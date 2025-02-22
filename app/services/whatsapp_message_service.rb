require "faraday"
require "json"

class WhatsappMessageService
  BASE_URI = "http://localhost:5000"  # Altere para o endpoint real do seu bot Python

  def self.send_message(recipient, content, image_url = nil)
    normalized_phone = recipient.gsub(/\D/, "")
    body = { phone: normalized_phone, message: content }
    body[:image_url] = image_url if image_url.present?

    connection = Faraday.new(url: BASE_URI) do |conn|
      conn.request :json
      conn.adapter Faraday.default_adapter
    end

    connection.post("/send_message", body.to_json, "Content-Type" => "application/json")
  end

  def self.interpolate_message(content, family)
    # Substitui a tag {familia_nome} pelo nome da família
    content.gsub("{familia_nome}", family.name)
  end
end
