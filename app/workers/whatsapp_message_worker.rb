class WhatsappMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = WhatsappMessage.find(message_id)
    message.update(status: "sending")

    image_url = if message.image.attached?
                  Rails.application.routes.url_helpers.rails_blob_url(message.image, only_path: false)
    end

    message.families.each do |family|
      recipient = family.phone.gsub(/\D/, "")
      # Interpola o conteúdo da mensagem, substituindo {familia_nome} pelo nome da família
      interpolated_message = WhatsappMessageService.interpolate_message(message.content, family)

      response = WhatsappMessageService.send_message(recipient, interpolated_message, image_url)

      if response.status == 200
        message.increment!(:sent_count)
      else
        message.increment!(:failed_count)
      end

      ActionCable.server.broadcast "whatsapp_messages_channel", {
        id: message.id,
        status: message.status,
        sent_count: message.sent_count,
        total_count: message.total_count
      }
    end

    if message.sent_count == message.total_count
      message.update(status: "sent")
    elsif message.failed_count == message.total_count
      message.update(status: "failed")
    else
      message.update(status: "partial")
    end

    ActionCable.server.broadcast "whatsapp_messages_channel", {
      id: message.id,
      status: message.status,
      sent_count: message.sent_count,
      total_count: message.total_count
    }
  end
end
