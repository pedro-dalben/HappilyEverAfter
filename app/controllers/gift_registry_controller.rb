class GiftRegistryController < ApplicationController
  layout "gift_registry"
  before_action :authenticate_with_token, only: [ :index, :add_to_cart, :cart, :remove_from_cart, :checkout, :buy_now, :empty_cart ]
  skip_before_action :authenticate_with_token, only: [ :authenticate, :verify_token, :payment_webhook ]
  skip_before_action :verify_authenticity_token, only: [:payment_webhook]

  def index
    @gift_items = GiftItem.active
  end

  def add_to_cart
    id = params[:id].to_i
    session[:cart] ||= []
    session[:cart] << id

    gift_item = GiftItem.find_by(id: id)
    item_name = gift_item ? gift_item.name : "Item"
    cart_count = session[:cart].size

    respond_to do |format|
      format.html {
        redirect_to gift_registry_path, notice: "Item adicionado ao carrinho.", status: :see_other
      }
      format.json {
        render json: {
          cart_count: cart_count,
          message: "#{item_name} adicionado ao carrinho com sucesso!",
          success: true
        }, status: :ok
      }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace("cart-counter",
            partial: "gift_registry/cart_counter",
            locals: { count: cart_count }),
          turbo_stream.append("toast-container",
            partial: "shared/toast",
            locals: { message: "#{item_name} adicionado ao carrinho com sucesso!" })
        ]
      }
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

    redirect_to cart_path, flash: { cart_notice: "Item removido do carrinho." }, status: :see_other
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
    redirect_to cart_path, notice: "Carrinho esvaziado.", status: :see_other
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

    # Associar o pedido à família atual
    if session[:family_token].present?
      @family = Family.find_by(token: session[:family_token])
      @order.family_id = @family.id if @family
    end

    # Calcular total
    cart_total = calculate_total_from_cart
    @order.total = cart_total

    # Inicializar @cart_items e @total para garantir que estão disponíveis
    prepare_cart_items

    if @cart_items.blank? || @total == 0
      flash[:alert] = "Seu carrinho está vazio. Adicione itens antes de finalizar o pedido."
      return redirect_to gift_registry_path
    end

    if @order.save
      original_total = @order.total  # Guardar o total original

      # Cria os itens do pedido
      create_order_items(@order)

      # Integração com Asaas
      begin
        customer_data = create_asaas_customer(@order)

        if customer_data && customer_data["id"]
          # Atualizar customer_id sem recalcular o total
          @order.update_columns(asaas_customer_id: customer_data["id"])

          # Forçar o total original
          @order.update_columns(total: original_total)

          payment_data = create_asaas_payment(@order, customer_data["id"])

          if payment_data && payment_data["id"]
            # Atualiza o pedido com os dados do pagamento
            @order.update(
              asaas_payment_id: payment_data["id"],
              payment_url: payment_data["invoiceUrl"] || payment_data["bankSlipUrl"] || payment_data["pixQrCodeUrl"],
              payment_data: payment_data.to_json
            )

            # Salvar dados na sessão para recuperação futura
            session[:last_order_id] = @order.id

            # Limpa o carrinho após finalização
            session[:cart] = []

            # Garantir que temos uma URL de pagamento válida
            payment_url = @order.payment_url.presence || order_status_path(@order)

            # Redirecionar para a página de transição
            return redirect_to payment_transition_path(id: @order.id)
          else
            error_message = payment_data && payment_data["errors"] ? payment_data["errors"].map { |e| e["description"] }.join(", ") : "Erro desconhecido ao processar pagamento"
            @order.update(status: "failed", error_message: error_message)
            flash[:alert] = "Erro ao processar pagamento: #{error_message}"
          end
        else
          error_message = customer_data && customer_data["errors"] ? customer_data["errors"].map { |e| e["description"] }.join(", ") : "Erro desconhecido ao criar cliente"
          @order.update(status: "failed", error_message: error_message)
          flash[:alert] = "Erro ao criar cliente: #{error_message}"
        end
      rescue => e
        @order.update(status: "failed", error_message: e.message)
        flash[:alert] = "Erro inesperado durante processamento: #{e.message}"
      end

      # Se chegou aqui é porque houve algum erro no processo
      redirect_to checkout_path
    else
      error_messages = @order.errors.full_messages.join(", ")
      flash[:alert] = "Erro ao salvar pedido: #{error_messages}"
      redirect_to checkout_path
    end
  end

  def calculate_total_from_cart
    total = 0
    return total unless session[:cart].present?

    item_counts = Hash.new(0)
    session[:cart].each { |id| item_counts[id] += 1 }

    item_counts.each do |id, quantity|
      gift_item = GiftItem.find_by(id: id)
      if gift_item
        total += gift_item.price * quantity
      end
    end

    total
  end

  def create_asaas_payment(order, customer_id)
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

  # Webhook para receber notificações do Asaas
  def payment_webhook
    # Log da requisição para debug
    Rails.logger.info("Recebido webhook do Asaas: #{request.raw_post}")
    Rails.logger.info("User-Agent: #{request.user_agent}")
    Rails.logger.info("IP Remoto: #{request.remote_ip}")
    Rails.logger.info("Cabeçalhos: #{request.headers.select { |k, v| k =~ /^HTTP_/ }.inspect}")

    # Parse do payload (com tratamento de erro)
    begin
      payload = JSON.parse(request.raw_post)
    rescue JSON::ParserError
      Rails.logger.error("Erro ao fazer parse do payload JSON: #{request.raw_post}")
      return render json: { error: "Invalid JSON" }, status: :bad_request
    end

    # Verificar se temos um evento e ID de evento
    event = payload["event"]
    event_id = payload["id"]

    unless event
      Rails.logger.error("Webhook sem evento: #{payload}")
      return render json: { error: "Missing event" }, status: :bad_request
    end

    # Verificar se o evento já foi processado
    if event_id.present?
      if ProcessedWebhook.exists?(event_id: event_id)
        Rails.logger.info("Evento #{event_id} já foi processado anteriormente")
        return render json: { success: true, message: "Event already processed" }, status: :ok
      end
    end

    payment_id = payload["payment"]["id"] if payload["payment"]

    # Eventos que não precisam de pedido para processar
    if event == "PAYMENT_CHECKOUT_VIEWED"
      # Registrar que processamos este evento
      ProcessedWebhook.create(event_id: event_id, payload: payload.to_json) if event_id.present?
      Rails.logger.info("Cliente visualizou a página de checkout para pagamento #{payment_id}")
      return render json: { success: true }, status: :ok
    end

    # Para outros eventos, precisamos do ID do pagamento
    unless payment_id
      Rails.logger.error("Webhook sem ID de pagamento: #{payload}")
      return render json: { error: "Missing payment ID" }, status: :bad_request
    end

    # Buscar o pedido relacionado
    order = Order.find_by(asaas_payment_id: payment_id)

    unless order
      Rails.logger.error("Nenhum pedido encontrado para o pagamento ID: #{payment_id}")
      return render json: { error: "Order not found" }, status: :not_found
    end

    # Processar o evento
    case event
    when "PAYMENT_CREATED"
      order.update(
        payment_data: payload.to_json
      )
      Rails.logger.info("Pagamento #{payment_id} criado para pedido #{order.id}")
    when "PAYMENT_RECEIVED", "PAYMENT_CONFIRMED", "PAYMENT_APPROVED"
      order.update(
        status: "paid",
        payment_data: payload.to_json,
        paid_at: Time.current
      )
      Rails.logger.info("Pagamento #{payment_id} confirmado para pedido #{order.id}")
    when "PAYMENT_OVERDUE"
      order.update(status: "overdue", payment_data: payload.to_json)
      Rails.logger.info("Pagamento #{payment_id} vencido para pedido #{order.id}")
    when "PAYMENT_REFUNDED"
      order.update(status: "refunded", payment_data: payload.to_json)
      Rails.logger.info("Pagamento #{payment_id} reembolsado para pedido #{order.id}")
    when "PAYMENT_DELETED", "PAYMENT_CANCELED"
      order.update(status: "cancelled", payment_data: payload.to_json)
      Rails.logger.info("Pagamento #{payment_id} cancelado para pedido #{order.id}")
    else
      Rails.logger.info("Evento não processado: #{event} para pagamento #{payment_id}")
    end

    # Registrar que processamos este evento
    ProcessedWebhook.create(event_id: event_id, payload: payload.to_json) if event_id.present?

    # Retornar sucesso
    render json: { success: true }, status: :ok
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

  def authenticate
    # Se já tiver um token válido na sessão, redireciona para a lista
    if session[:family_token].present?
      family = Family.find_by(token: session[:family_token].upcase)
      if family.present?
        redirect_to gift_registry_path and return
      else
        # Limpar token inválido
        session[:family_token] = nil
      end
    end

    # Renderiza o formulário de autenticação
    render :authenticate
  end

  def verify_token
    token = params[:token]

    if token.present?
      family = Family.find_by(token: token.upcase)

      if family
        session[:family_token] = token.upcase
        flash[:notice] = "Bem-vindo à lista de presentes do casamento!"
        redirect_to gift_registry_path
      else
        flash.now[:alert] = "Código inválido. Por favor, tente novamente."
        render :authenticate
      end
    else
      flash.now[:alert] = "Por favor, informe o código de acesso."
      render :authenticate
    end
  end

  def family_purchases
    token = params[:token]
    @family = Family.find_by(token: token.upcase)

    if @family.nil?
      flash[:alert] = "Token de família inválido"
      return redirect_to root_path
    end

    # Simplificar a consulta - usar apenas family_id
    @orders = Order.where(family_id: @family.id).order(created_at: :desc)

    # Para pedidos pendentes, verificar status atual no Asaas
    @orders.where(status: "pending").each do |order|
      if order.asaas_payment_id.present?
        payment_data = AsaasService.find_payment(order.asaas_payment_id)

        if payment_data && payment_data["status"] && !payment_data["errors"]
          # Mapear status do Asaas para status do sistema
          status_mapping = {
            "PENDING" => "pending",
            "RECEIVED" => "paid",
            "CONFIRMED" => "paid",
            "OVERDUE" => "overdue",
            "REFUNDED" => "refunded",
            "DELETED" => "cancelled"
          }

          new_status = status_mapping[payment_data["status"]] || order.status

          # Atualizar status se mudou
          if new_status != order.status
            order.update(
              status: new_status,
              payment_data: payment_data.to_json,
              paid_at: (new_status == "paid") ? Time.current : nil
            )
          end
        end
      end
    end

    # Agrupar pedidos por status para facilitar a visualização
    @paid_orders = @orders.where(status: "paid")
    @pending_orders = @orders.where(status: "pending")
    @other_orders = @orders.where.not(status: ["paid", "pending"])
  end

  private

  def order_params
    params.require(:order).permit(:customer_name, :customer_email, :customer_phone, :customer_cpf_cnpj, :payment_method)
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

  def authenticate_with_token
    token = params[:token] || session[:family_token]

    if token.present?
      @family = Family.find_by(token: token.upcase)
      if @family
        # Salvar o token na sessão para futuras requisições
        session[:family_token] = token.upcase
        return true
      end
    end

    # Prevenir loop infinito - não redirecionar se já estiver na página de autenticação
    return true if [ "authenticate", "verify_token" ].include?(action_name)

    # Redirecionar para a página de autenticação se token não for válido
    flash[:alert] = "É necessário um código válido para acessar a lista de presentes"
    redirect_to gift_registry_authenticate_path
  end
end
