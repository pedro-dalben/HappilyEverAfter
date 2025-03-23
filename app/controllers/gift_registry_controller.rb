class GiftRegistryController < ApplicationController
  def index
    @gift_items = GiftItem.all
  end

  def add_to_cart
    id = params[:id].to_i
    session[:cart] ||= []
    session[:cart] << id

    respond_to do |format|
      format.html { redirect_to gift_registry_path, notice: "Item adicionado ao carrinho." }
      format.json { render json: { cart_count: session[:cart].size }, status: :ok }
    end
  end

  def cart
    @cart_items = []
    @total = 0

    if session[:cart].present?
      item_counts = Hash.new(0)
      session[:cart].each { |id| item_counts[id] += 1 }

      item_counts.each do |id, quantity|
        gift_item = GiftItem.find_by(id: id)
        if gift_item
          @cart_items << {
            item: gift_item,
            quantity: quantity,
            subtotal: gift_item.price * quantity
          }
          @total += gift_item.price * quantity
        end
      end
    end
  end

  def remove_from_cart
    id = params[:id].to_i
    session[:cart].delete_at(session[:cart].index(id) || session[:cart].length)

    redirect_to cart_path, notice: "Item removido do carrinho."
  end

  def checkout
    @order = Order.new
    @cart_items = []
    @total = 0

    if session[:cart].present?
      item_counts = Hash.new(0)
      session[:cart].each { |id| item_counts[id] += 1 }

      item_counts.each do |id, quantity|
        gift_item = GiftItem.find_by(id: id)
        if gift_item
          @cart_items << {
            item: gift_item,
            quantity: quantity,
            subtotal: gift_item.price * quantity
          }
          @total += gift_item.price * quantity
        end
      end
    end
  end

  def buy_now
    id = params[:id].to_i
    session[:cart] = [ id ]

    redirect_to checkout_path
  end

  def empty_cart
    session[:cart] = []
    redirect_to cart_path, notice: "Carrinho esvaziado."
  end

  def thank_you
    @order = Order.find(params[:id])

    # Redirecionar para a página de status se o pagamento não estiver confirmado
    redirect_to order_status_path(@order) unless @order.status == "paid"

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Pedido não encontrado"
  end

  def process_payment
    @order = Order.new(order_params)
    @order.status = "pending"
    @order.total = calculate_total_from_cart

    if @order.save
      # Cria os itens do pedido
      create_order_items(@order)

      # Integração com Asaas
      customer_data = create_asaas_customer(@order)

      if customer_data && customer_data["id"]
        @order.update(asaas_customer_id: customer_data["id"])

        payment_data = create_asaas_payment(@order, customer_data["id"])

        if payment_data && payment_data["id"]
          # Atualiza o pedido com os dados do pagamento
          @order.update(
            asaas_payment_id: payment_data["id"],
            payment_url: payment_data["invoiceUrl"],
            payment_data: payment_data.to_json
          )

          # Salvar dados na sessão para recuperação futura
          session[:last_order_id] = @order.id

          # Limpa o carrinho após finalização
          session[:cart] = []

          redirect_to payment_transition_path(id: @order.id)
        else
          @order.update(status: "failed")
          flash[:alert] = "Erro ao processar pagamento"
          redirect_to checkout_path
        end
      else
        @order.update(status: "failed")
        flash[:alert] = "Erro ao criar cliente"
        redirect_to checkout_path
      end
    else
      flash[:alert] = "Erro ao salvar pedido: #{@order.errors.full_messages.join(', ')}"
      redirect_to checkout_path
    end
  end

  # Webhook para receber notificações do Asaas
  def payment_webhook
    # Verificar token de autenticação (segurança adicional)
    webhook_token = request.headers["asaas-access-token"]
    return render json: { error: "Não autorizado" }, status: :unauthorized unless webhook_token == ENV["ASAAS_WEBHOOK_TOKEN"]

    # Processar o evento
    payload = JSON.parse(request.body.read)
    event_id = payload["id"]

    # Verificar se este evento já foi processado (idempotência)
    return render json: { received: true }, status: :ok if ProcessedWebhook.exists?(event_id: event_id)

    # Processar o evento baseado no tipo
    case payload["event"]
    when "PAYMENT_CREATED"
      process_payment_created(payload["payment"])
    when "PAYMENT_RECEIVED", "PAYMENT_CONFIRMED"
      process_payment_confirmed(payload["payment"])
    when "PAYMENT_OVERDUE"
      process_payment_overdue(payload["payment"])
    when "PAYMENT_DELETED", "PAYMENT_RESTORED", "PAYMENT_REFUNDED", "PAYMENT_UPDATED"
      process_payment_update(payload["payment"])
    end

    # Registrar evento como processado
    ProcessedWebhook.create(event_id: event_id, payload: payload.to_json)

    # Responder ao webhook
    render json: { received: true }, status: :ok
  end

  # Página de status do pedido
  def order_status
    @order = Order.find(params[:id])

    # Verificar status atual no Asaas se o pedido estiver pendente
    if @order.status == "pending" && @order.asaas_payment_id.present?
      payment_data = AsaasService.find_payment(@order.asaas_payment_id)

      if payment_data && payment_data["status"]
        # Mapear status do Asaas para status do sistema
        status_mapping = {
          "PENDING" => "pending",
          "RECEIVED" => "paid",
          "CONFIRMED" => "paid",
          "OVERDUE" => "overdue",
          "REFUNDED" => "refunded",
          "DELETED" => "cancelled"
        }

        new_status = status_mapping[payment_data["status"]] || @order.status
        @order.update(
          status: new_status,
          payment_data: payment_data.to_json
        )
      end
    end

    # Redirecionar para página de agradecimento se já estiver pago
    if @order.status == "paid"
      redirect_to thank_you_path(@order) and return
    end

    render :order_status
  end

  def payment_transition
    @order = Order.find(params[:id])
    @payment_url = @order.payment_url
  end

  private

  def order_params
    params.require(:order).permit(:customer_name, :customer_email, :customer_phone, :customer_cpf_cnpj, :payment_method)
  end

  def calculate_total_from_cart
    total = 0
    return total unless session[:cart].present?

    item_counts = Hash.new(0)
    session[:cart].each { |id| item_counts[id] += 1 }

    item_counts.each do |id, quantity|
      gift_item = GiftItem.find_by(id: id)
      total += gift_item.price * quantity if gift_item
    end

    total
  end

  def create_order_items(order)
    item_counts = Hash.new(0)
    session[:cart].each { |id| item_counts[id] += 1 }

    item_counts.each do |id, quantity|
      gift_item = GiftItem.find_by(id: id)
      if gift_item
        order.order_items.create(
          gift_item_id: gift_item.id,
          quantity: quantity,
          price: gift_item.price
        )
      end
    end
  end

  def prepare_cart_items
    @cart_items = []
    @total = 0

    if session[:cart].present?
      item_counts = Hash.new(0)
      session[:cart].each { |id| item_counts[id] += 1 }

      item_counts.each do |id, quantity|
        gift_item = GiftItem.find_by(id: id)
        if gift_item
          @cart_items << {
            item: gift_item,
            quantity: quantity,
            subtotal: gift_item.price * quantity
          }
          @total += gift_item.price * quantity
        end
      end
    end
  end

  def create_asaas_customer(order)
    customer_data = {
      name: order.customer_name,
      email: order.customer_email,
      phone: order.customer_phone,
      cpfCnpj: order.customer_cpf_cnpj.gsub(/[^0-9]/, ""), # Remove caracteres não numéricos
      notificationDisabled: false
    }

    AsaasService.create_customer(customer_data)
  end

  def create_asaas_payment(order, customer_id)
    # Cria pagamento baseado no método de pagamento selecionado
    payment_data = {
      customer: customer_id,
      billingType: order.payment_method == "credit_card" ? "CREDIT_CARD" : "PIX",
      value: order.total,
      dueDate: Date.today.strftime("%Y-%m-%d"),
      description: "Pedido ##{order.id}",
      externalReference: order.id.to_s,
      postalService: false,
      callback: {
        successUrl: thank_you_url(order),
        autoRedirect: true
      }
    }

    AsaasService.create_payment(payment_data)
  end

  def process_payment_created(payment_data)
    # Atualiza informações adicionais quando o pagamento é criado
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    # Atualizar dados adicionais se necessário
    order.update(payment_data: payment_data.to_json)
  end

  def process_payment_confirmed(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    order.update(
      status: "paid",
      payment_data: payment_data.to_json
    )
  end

  def process_payment_overdue(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    order.update(
      status: "overdue",
      payment_data: payment_data.to_json
    )
  end

  def process_payment_update(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    # Mapear status do Asaas para status do sistema
    status_mapping = {
      "PENDING" => "pending",
      "RECEIVED" => "paid",
      "CONFIRMED" => "paid",
      "OVERDUE" => "overdue",
      "REFUNDED" => "refunded",
      "DELETED" => "cancelled"
    }

    order.update(
      status: status_mapping[payment_data["status"]] || order.status,
      payment_data: payment_data.to_json
    )
  end
end
