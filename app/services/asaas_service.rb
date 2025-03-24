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
      "access_token" => ENV["ASAAS_API_KEY"] || Rails.application.credentials.asaas[:api_key]
    }
  end

  def self.create_customer(customer_data)
    Rails.logger.info("Criando cliente no Asaas: #{customer_data.inspect}")

    begin
      response = HTTParty.post(
        "#{base_uri}/customers",
        body: customer_data.to_json,
        headers: headers
      )

      Rails.logger.info("Resposta do Asaas (criar cliente): Status: #{response.code}, Body: #{response.body}")

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Erro ao criar cliente no Asaas: #{response.code} - #{response.body}")
        error_body = JSON.parse(response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
        error_body
      end
    rescue => e
      Rails.logger.error("Exceção ao criar cliente no Asaas: #{e.message}")
      { "errors" => [ { "description" => "Erro de comunicação: #{e.message}" } ] }
    end
  end

  def self.find_customer(customer_id)
    Rails.logger.info("Buscando cliente no Asaas: #{customer_id}")

    begin
      response = HTTParty.get(
        "#{base_uri}/customers/#{customer_id}",
        headers: headers
      )

      Rails.logger.info("Resposta do Asaas (buscar cliente): Status: #{response.code}, Body: #{response.body}")

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Erro ao buscar cliente no Asaas: #{response.code} - #{response.body}")
        error_body = JSON.parse(response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
        error_body
      end
    rescue => e
      Rails.logger.error("Exceção ao buscar cliente no Asaas: #{e.message}")
      { "errors" => [ { "description" => "Erro de comunicação: #{e.message}" } ] }
    end
  end

  def self.create_payment(payment_data)
    Rails.logger.info("Criando pagamento no Asaas: #{payment_data.inspect}")

    begin
      response = HTTParty.post(
        "#{base_uri}/payments",
        body: payment_data.to_json,
        headers: headers
      )

      Rails.logger.info("Resposta do Asaas (criar pagamento): Status: #{response.code}, Body: #{response.body}")

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Erro ao criar pagamento no Asaas: #{response.code} - #{response.body}")
        error_body = JSON.parse(response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
        error_body
      end
    rescue => e
      Rails.logger.error("Exceção ao criar pagamento no Asaas: #{e.message}")
      { "errors" => [ { "description" => "Erro de comunicação: #{e.message}" } ] }
    end
  end

  def self.find_payment(payment_id)
    Rails.logger.info("Buscando pagamento no Asaas: #{payment_id}")

    begin
      response = HTTParty.get(
        "#{base_uri}/payments/#{payment_id}",
        headers: headers
      )

      Rails.logger.info("Resposta do Asaas (buscar pagamento): Status: #{response.code}, Body: #{response.body}")

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Erro ao buscar pagamento no Asaas: #{response.code} - #{response.body}")
        error_body = JSON.parse(response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
        error_body
      end
    rescue => e
      Rails.logger.error("Exceção ao buscar pagamento no Asaas: #{e.message}")
      { "errors" => [ { "description" => "Erro de comunicação: #{e.message}" } ] }
    end
  end
end
