class WhatsappMessageWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, dead: false, queue: "default"

  sidekiq_retry_in do |count|
    10 * (count + 1) ** 2  # 10s, 40s, 90s
  end

  def perform(message_id)
    sleep 3 unless Rails.env.test?

    logger.info("Iniciando processamento da mensagem WhatsApp ID=#{message_id}")

    exists = ActiveRecord::Base.connection.select_value("SELECT EXISTS(SELECT 1 FROM whatsapp_messages WHERE id = #{message_id})")

    if exists
      logger.info("Verificação prévia: mensagem #{message_id} existe no banco de dados")
    else
      logger.error("Verificação prévia: mensagem #{message_id} NÃO existe no banco de dados")
    end

    message = WhatsappMessage.find_by(id: message_id)

    unless message
      logger.error("Mensagem WhatsApp com ID #{message_id} não encontrada")
      raise ActiveRecord::RecordNotFound, "Mensagem WhatsApp com ID #{message_id} não encontrada"
    end

    logger.info("Mensagem encontrada: ID=#{message.id}, status=#{message.status}, famílias=#{message.families.count}")
    message.update(status: "sending")

    image_url = if message.image.attached?
                  Rails.application.routes.url_helpers.rails_blob_url(message.image, only_path: false)
    end

    families = message.families.to_a
    total_families = families.size

    families.each_with_index do |family, index|
      logger.info("Processando família #{index+1}/#{total_families}: #{family.name} (ID: #{family.id})")

      begin
        recipient = family.phone.gsub(/\D/, "")
        interpolated_message = WhatsappMessageService.interpolate_message(message.content, family)

        logger.info("Enviando mensagem para #{recipient}")
        response = WhatsappMessageService.send_message(recipient, interpolated_message, image_url)

        if response.status == 200
          logger.info("Mensagem enviada com sucesso para #{recipient}")
          message.increment!(:sent_count)
        else
          logger.error("Falha ao enviar mensagem para #{recipient}. Status: #{response.status}, Corpo: #{response.body}")
          message.increment!(:failed_count)
        end

        # Atualiza o status em tempo real via ActionCable
        ActionCable.server.broadcast "whatsapp_messages_channel", {
          id: message.id,
          status: message.status,
          sent_count: message.sent_count,
          total_count: message.total_count
        }

        if index < total_families - 1
          logger.info("Aguardando 1 segundo antes do próximo envio")
          sleep 1 unless Rails.env.test?
        end

      rescue => e
        logger.error("Erro ao processar família #{family.id}: #{e.message}")
        message.increment!(:failed_count)
      end
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

    logger.info("Concluído o processamento da mensagem #{message_id} com status final: #{message.status}")
  end
end
