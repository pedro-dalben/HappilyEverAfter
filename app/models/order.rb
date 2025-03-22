class Order < ApplicationRecord
  belongs_to :family, optional: true
  has_many :order_items, dependent: :destroy
  has_many :gift_items, through: :order_items

  validates :customer_name, :customer_email, :customer_phone, :customer_cpf_cnpj, presence: true
  validates :customer_cpf_cnpj, format: { with: /\A\d{11,14}\z/, message: "deve conter apenas números (11 dígitos para CPF ou 14 para CNPJ)" }

  def ready_for_payment?
    status == "ready_for_payment"
  end

  def add_item(gift_item, quantity = 1)
    existing_item = order_items.find_by(gift_item_id: gift_item.id)

    if existing_item
      existing_item.update(quantity: existing_item.quantity + quantity)
    else
      order_items.create(gift_item: gift_item, quantity: quantity, price: gift_item.price)
    end

    update_total
  end

  def update_total
    self.total = order_items.sum { |item| item.price * item.quantity }
    save
  end

  def create_asaas_payment
    return false if customer_name.blank? || customer_email.blank? || customer_phone.blank?

    customer = create_or_find_asaas_customer

    payment_data = {
      customer: customer.id,
      billingType: payment_method == "credit_card" ? "CREDIT_CARD" : "PIX",
      value: total,
      dueDate: (Date.today + 3.days).strftime("%Y-%m-%d"),
      description: "Presente de Casamento - Pedro & Giovana",
      externalReference: id.to_s
    }

    response = AsaasService.create_payment(payment_data)

    if response && response["id"]
      update(
        asaas_payment_id: response["id"],
        payment_url: response["invoiceUrl"],
        payment_data: response.to_json,
        status: "waiting_payment"
      )
      true
    else
      false
    end
  end

  private

  def create_or_find_asaas_customer
    if asaas_customer_id.present?
      response = AsaasService.find_customer(asaas_customer_id)
      return response if response && response["id"]
    end

    # Cria um novo cliente no Asaas
    customer_data = {
      name: customer_name,
      email: customer_email,
      phone: customer_phone.gsub(/\D/, ""),
      cpfCnpj: customer_cpf_cnpj.gsub(/[^0-9]/, "")
    }

    response = AsaasService.create_customer(customer_data)

    if response && response["id"]
      update(asaas_customer_id: response["id"])
    end

    response
  end
end
