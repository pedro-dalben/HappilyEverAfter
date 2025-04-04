class AsaasService
  include HTTParty

  SANDBOX_URL = "https://sandbox.asaas.com/api/v3".freeze
  PRODUCTION_URL = "https://www.asaas.com/api/v3".freeze

  def self.base_uri
    ENV["ASAAS_ENVIRONMENT"] == "production" ? PRODUCTION_URL : SANDBOX_URL
  end

  def self.headers
    api_key = ENV["ASAAS_API_KEY"]
    # Registrar a chave para debugging
    Rails.logger.info("Usando chave da API Asaas: #{api_key.nil? ? 'Não encontrada' : api_key[0..10] + '...'}")

    {
      "Content-Type" => "application/json",
      "access_token" => api_key || Rails.application.credentials.asaas[:api_key]
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

  def self.configure_webhook(webhook_url)
    Rails.logger.info("Configurando webhook no Asaas: #{webhook_url}")

    webhook_data = {
      url: webhook_url,
      email: "admin@giovanaepedro.com.br",
      apiVersion: 3,
      enabled: true,
      interrupted: false,
      authToken: SecureRandom.hex(16),
      events: [
        "PAYMENT_CREATED",
        "PAYMENT_RECEIVED",
        "PAYMENT_CONFIRMED",
        "PAYMENT_OVERDUE",
        "PAYMENT_DELETED",
        "PAYMENT_REFUNDED",
        "PAYMENT_CHECKOUT_VIEWED"
      ]
    }

    begin
      # Primeiro verifica se já existe algum webhook configurado
      response = HTTParty.get(
        "#{base_uri}/webhook",
        headers: headers
      )

      Rails.logger.info("Resposta do Asaas (buscar webhooks): Status: #{response.code}, Body: #{response.body}")

      if response.success?
        webhooks = JSON.parse(response.body)

        if webhooks && webhooks["data"] && webhooks["data"].size > 0
          # Atualiza o primeiro webhook existente
          webhook_id = webhooks["data"].first["id"]

          update_response = HTTParty.put(
            "#{base_uri}/webhook/#{webhook_id}",
            body: webhook_data.to_json,
            headers: headers
          )

          Rails.logger.info("Resposta do Asaas (atualizar webhook): Status: #{update_response.code}, Body: #{update_response.body}")

          if update_response.success?
            JSON.parse(update_response.body)
          else
            Rails.logger.error("Erro ao atualizar webhook no Asaas: #{update_response.code} - #{update_response.body}")
            error_body = JSON.parse(update_response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
            error_body
          end
        else
          # Cria um novo webhook
          create_response = HTTParty.post(
            "#{base_uri}/webhook",
            body: webhook_data.to_json,
            headers: headers
          )

          Rails.logger.info("Resposta do Asaas (criar webhook): Status: #{create_response.code}, Body: #{create_response.body}")

          if create_response.success?
            JSON.parse(create_response.body)
          else
            Rails.logger.error("Erro ao criar webhook no Asaas: #{create_response.code} - #{create_response.body}")
            error_body = JSON.parse(create_response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
            error_body
          end
        end
      else
        Rails.logger.error("Erro ao buscar webhooks no Asaas: #{response.code} - #{response.body}")
        error_body = JSON.parse(response.body) rescue { "errors" => [ { "description" => "Erro de comunicação com Asaas" } ] }
        error_body
      end
    rescue => e
      Rails.logger.error("Exceção ao configurar webhook no Asaas: #{e.message}")
      { "errors" => [ { "description" => "Erro de comunicação: #{e.message}" } ] }
    end
  end
end
