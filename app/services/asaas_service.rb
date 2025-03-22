class AsaasService
  include HTTParty

  SANDBOX_URL = "https://sandbox.asaas.com/api/v3".freeze
  PRODUCTION_URL = "https://www.asaas.com/api/v3".freeze

  def self.base_uri
    Rails.env.production? ? PRODUCTION_URL : SANDBOX_URL
  end

  def self.headers
    {
      "Content-Type" => "application/json",
      "access_token" => ENV["ASAAS_API_KEY"]
    }
  end

  def self.create_customer(customer_data)
    response = HTTParty.post(
      "#{base_uri}/customers",
      body: customer_data.to_json,
      headers: headers
    )

    JSON.parse(response.body) if response.success?
  end

  def self.find_customer(customer_id)
    response = HTTParty.get(
      "#{base_uri}/customers/#{customer_id}",
      headers: headers
    )

    JSON.parse(response.body) if response.success?
  end

  def self.create_payment(payment_data)
    response = HTTParty.post(
      "#{base_uri}/payments",
      body: payment_data.to_json,
      headers: headers
    )

    JSON.parse(response.body) if response.success?
  end

  def self.find_payment(payment_id)
    response = HTTParty.get(
      "#{base_uri}/payments/#{payment_id}",
      headers: headers
    )

    JSON.parse(response.body) if response.success?
  end
end
