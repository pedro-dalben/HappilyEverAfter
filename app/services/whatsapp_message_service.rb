require "faraday"
require "json"

class WhatsappMessageService
  BASE_URI = "http://localhost:5000"  # Altere para o endpoint real do seu bot Python

  def self.send_message(recipient, content, image_url = nil)
    normalized_phone = recipient.gsub(/\D/, "")
    return failed_response("Número de telefone vazio") if normalized_phone.blank?
    return failed_response("Conteúdo da mensagem vazio") if content.blank?

    body = { phone: normalized_phone, message: content }
    body[:image_url] = image_url if image_url.present?

    begin
      connection = Faraday.new(url: BASE_URI) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
        conn.options.timeout = 15  # timeout em segundos (aumentado para 15s)
        conn.options.open_timeout = 5  # timeout de conexão em segundos
      end

      Rails.logger.info("Enviando requisição para #{BASE_URI}/send_message: #{body.to_json}")
      response = connection.post("/send_message", body.to_json, "Content-Type" => "application/json")

      if response.status == 200
        Rails.logger.info("Mensagem enviada com sucesso para #{normalized_phone}")
      else
        Rails.logger.error("Falha ao enviar mensagem: #{response.status} - #{response.body}")
      end

      response
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error("Erro de conexão ao enviar mensagem WhatsApp: #{e.message}")
      failed_response("Erro de conexão: #{e.message}")
    rescue Faraday::TimeoutError => e
      Rails.logger.error("Timeout ao enviar mensagem WhatsApp: #{e.message}")
      failed_response("Timeout na requisição: #{e.message}")
    rescue => e
      Rails.logger.error("Erro desconhecido ao enviar mensagem WhatsApp: #{e.message}")
      failed_response("Erro: #{e.message}")
    end
  end

  def self.interpolate_message(content, family)
    return content unless family.present?
    # Substitui a tag {familia_nome} pelo nome da família
    interpolated = content.to_s.gsub("{familia_nome}", family.name.to_s)
    interpolated = interpolated.to_s.gsub("{familia_codigo}", family.token.to_s)

    interpolated
  end

  private

  def self.failed_response(message)
    # Cria uma resposta fake para manter a compatibilidade com o código existente
    Faraday::Response.new(
      status: 500,
      body: { error: message }.to_json,
      response_headers: { "Content-Type" => "application/json" }
    )
  end
end
