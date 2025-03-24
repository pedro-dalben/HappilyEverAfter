class GiftRegistryController < ApplicationController
  before_action :authenticate_with_token, only: [ :index, :add_to_cart, :cart, :remove_from_cart, :checkout, :buy_now, :empty_cart ]

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

    # Inicializar @cart_items e @total para garantir que estão disponíveis
    prepare_cart_items

    if @cart_items.blank? || @total == 0
      flash[:alert] = "Seu carrinho está vazio. Adicione itens antes de finalizar o pedido."
      return redirect_to gift_registry_path
    end

    Rails.logger.info("Iniciando processamento de pagamento: #{@order.attributes.inspect}")
    Rails.logger.info("Carrinho contém #{@cart_items.size} itens, total: #{@total}")

    if @order.save
      # Cria os itens do pedido
      create_order_items(@order)

      # Registrando informações para debug
      Rails.logger.info("Pedido criado com sucesso. ID: #{@order.id}")

      # Integração com Asaas
      begin
        customer_data = create_asaas_customer(@order)
        Rails.logger.info("Resposta do Asaas (cliente): #{customer_data.inspect}")

        if customer_data && customer_data["id"]
          @order.update(asaas_customer_id: customer_data["id"])

          payment_data = create_asaas_payment(@order, customer_data["id"])
          Rails.logger.info("Resposta do Asaas (pagamento): #{payment_data.inspect}")

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
            Rails.logger.info("Redirecionando para: #{payment_url}")

            # Redirecionar para a página de transição que então redirecionará para a URL de pagamento
            return redirect_to payment_transition_path(id: @order.id)
          else
            error_message = payment_data && payment_data["errors"] ? payment_data["errors"].map { |e| e["description"] }.join(", ") : "Erro desconhecido ao processar pagamento"
            Rails.logger.error("Erro ao criar pagamento no Asaas: #{error_message}")
            @order.update(status: "failed", error_message: error_message)
            flash[:alert] = "Erro ao processar pagamento: #{error_message}"
          end
        else
          error_message = customer_data && customer_data["errors"] ? customer_data["errors"].map { |e| e["description"] }.join(", ") : "Erro desconhecido ao criar cliente"
          Rails.logger.error("Erro ao criar cliente no Asaas: #{error_message}")
          @order.update(status: "failed", error_message: error_message)
          flash[:alert] = "Erro ao criar cliente: #{error_message}"
        end
      rescue => e
        Rails.logger.error("Exceção durante processamento de pagamento: #{e.message}\n#{e.backtrace.join("\n")}")
        @order.update(status: "failed", error_message: e.message)
        flash[:alert] = "Erro inesperado durante processamento: #{e.message}"
      end

      # Se chegou aqui é porque houve algum erro no processo
      redirect_to checkout_path
    else
      error_messages = @order.errors.full_messages.join(", ")
      Rails.logger.error("Erro ao salvar pedido: #{error_messages}")
      flash[:alert] = "Erro ao salvar pedido: #{error_messages}"
      redirect_to checkout_path
    end
  end

  # Webhook para receber notificações do Asaas
  def payment_webhook
    # Verificar token de autenticação (segurança adicional)
    webhook_token = request.headers["asaas-access-token"]
    Rails.logger.info("Webhook recebido do Asaas. Token: #{webhook_token.present? ? 'Presente' : 'Ausente'}")

    unless webhook_token == ENV["ASAAS_WEBHOOK_TOKEN"]
      Rails.logger.warn("Token de webhook inválido ou ausente")
      return render json: { error: "Não autorizado" }, status: :unauthorized
    end

    # Processar o evento
    begin
      payload = JSON.parse(request.body.read)
      event_id = payload["id"]
      event_type = payload["event"]

      Rails.logger.info("Processando webhook do Asaas: Evento #{event_type}, ID: #{event_id}")

      # Verificar se este evento já foi processado (idempotência)
      if ProcessedWebhook.exists?(event_id: event_id)
        Rails.logger.info("Evento #{event_id} já foi processado anteriormente. Ignorando.")
        return render json: { received: true, message: "Evento já processado anteriormente" }, status: :ok
      end

      # Verificar se o payload contém informações de pagamento
      unless payload["payment"].present?
        Rails.logger.warn("Payload do webhook não contém informações de pagamento")
        return render json: { error: "Dados de pagamento ausentes" }, status: :bad_request
      end

      payment_id = payload["payment"]["id"]
      payment_status = payload["payment"]["status"]
      external_reference = payload["payment"]["externalReference"]

      Rails.logger.info("Detalhes do pagamento: ID: #{payment_id}, Status: #{payment_status}, Ref: #{external_reference}")

      # Encontrar o pedido relacionado a este pagamento
      order = Order.find_by(asaas_payment_id: payment_id)

      if order.nil? && external_reference.present?
        order = Order.find_by(id: external_reference)

        # Se encontrou pelo external_reference mas não tinha o asaas_payment_id, atualizar
        if order.present? && order.asaas_payment_id.blank?
          order.update(asaas_payment_id: payment_id)
          Rails.logger.info("Atualizado asaas_payment_id para o pedido #{order.id}")
        end
      end

      unless order
        Rails.logger.warn("Nenhum pedido encontrado para o pagamento #{payment_id}")
        return render json: { error: "Pedido não encontrado" }, status: :not_found
      end

      # Processar o evento baseado no tipo
      case event_type
      when "PAYMENT_CREATED"
        process_payment_created(payload["payment"])
      when "PAYMENT_RECEIVED", "PAYMENT_CONFIRMED"
        process_payment_confirmed(payload["payment"])
      when "PAYMENT_OVERDUE"
        process_payment_overdue(payload["payment"])
      when "PAYMENT_DELETED", "PAYMENT_RESTORED", "PAYMENT_REFUNDED", "PAYMENT_UPDATED"
        process_payment_update(payload["payment"])
      else
        Rails.logger.info("Tipo de evento não processado: #{event_type}")
      end

      # Registrar evento como processado
      ProcessedWebhook.create(event_id: event_id, payload: payload.to_json)
      Rails.logger.info("Webhook processado com sucesso e registrado")

      # Responder ao webhook
      render json: { received: true, status: "processed" }, status: :ok
    rescue JSON::ParserError => e
      Rails.logger.error("Erro ao analisar JSON do webhook: #{e.message}")
      render json: { error: "Payload inválido" }, status: :bad_request
    rescue => e
      Rails.logger.error("Erro ao processar webhook: #{e.message}\n#{e.backtrace.join("\n")}")
      render json: { error: "Erro interno" }, status: :internal_server_error
    end
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
      family = Family.find_by(token: session[:family_token])
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
      family = Family.find_by(token: token)

      if family
        session[:family_token] = token
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
    # Verificar se o token está presente e é válido
    token = params[:token]
    @family = Family.find_by(token: token)

    if @family.nil?
      flash[:alert] = "Token de família inválido"
      return redirect_to root_path
    end

    # Buscar todos os pedidos desta família
    @orders = @family.orders.order(created_at: :desc)

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
    @other_orders = @orders.where.not(status: [ "paid", "pending" ])
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

    Rails.logger.info("Processando evento PAYMENT_CREATED para pedido #{order.id}")

    # Atualizar dados adicionais se necessário
    order.update(
      payment_data: payment_data.to_json,
      payment_url: payment_data["invoiceUrl"] || payment_data["bankSlipUrl"] || payment_data["pixQrCodeUrl"] || order.payment_url
    )

    Rails.logger.info("Pedido #{order.id} atualizado com informações de pagamento")
  end

  def process_payment_confirmed(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    Rails.logger.info("Processando evento de confirmação de pagamento para pedido #{order.id}")

    # Não alterar status se já estiver pago
    unless order.status == "paid"
      order.update(
        status: "paid",
        payment_data: payment_data.to_json,
        paid_at: Time.current
      )
      Rails.logger.info("Pagamento do pedido #{order.id} confirmado com sucesso")

      # Enviar email de confirmação de pagamento
      # OrderMailer.payment_confirmed(order).deliver_later
    else
      Rails.logger.info("Pedido #{order.id} já estava marcado como pago. Nenhuma alteração de status.")
    end
  end

  def process_payment_overdue(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    Rails.logger.info("Processando evento PAYMENT_OVERDUE para pedido #{order.id}")

    order.update(
      status: "overdue",
      payment_data: payment_data.to_json
    )

    Rails.logger.info("Status do pedido #{order.id} atualizado para vencido")

    # Notificar sobre pagamento vencido, se necessário
    # OrderMailer.payment_overdue(order).deliver_later
  end

  def process_payment_update(payment_data)
    order = Order.find_by(asaas_payment_id: payment_data["id"])
    return unless order

    Rails.logger.info("Processando atualização de pagamento para pedido #{order.id}. Status Asaas: #{payment_data['status']}")

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

    # Registrar mudança de status
    if new_status != order.status
      Rails.logger.info("Alterando status do pedido #{order.id} de '#{order.status}' para '#{new_status}'")

      # Definir paid_at se o status estiver mudando para pago
      paid_at = (new_status == "paid" && order.status != "paid") ? Time.current : order.paid_at

      order.update(
        status: new_status,
        payment_data: payment_data.to_json,
        paid_at: paid_at
      )

      # Enviar notificações apropriadas baseadas na mudança de status
      case new_status
      when "paid"
        # OrderMailer.payment_confirmed(order).deliver_later
        Rails.logger.info("Email de confirmação de pagamento enviado para #{order.customer_email}")
      when "refunded"
        # OrderMailer.payment_refunded(order).deliver_later
        Rails.logger.info("Email de reembolso enviado para #{order.customer_email}")
      end
    else
      # Atualizar apenas os dados de pagamento, sem mudar o status
      order.update(payment_data: payment_data.to_json)
      Rails.logger.info("Dados de pagamento atualizados para o pedido #{order.id}, sem alteração de status")
    end
  end

  def authenticate_with_token
    token = params[:token] || session[:family_token]

    if token.present?
      @family = Family.find_by(token: token)
      if @family
        # Salvar o token na sessão para futuras requisições
        session[:family_token] = token
        return true
      end
    end

    # Redirecionar para a página de autenticação se token não for válido
    flash[:alert] = "É necessário um código válido para acessar a lista de presentes"
    redirect_to gift_registry_authenticate_path
  end
end
