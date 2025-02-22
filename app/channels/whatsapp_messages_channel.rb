class WhatsappMessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "whatsapp_messages_channel"
  end

  def unsubscribed
  end
end
