module WhatsappMessagesHelper
  def messages_progress(messages)
    total = messages.count
    processed = messages.where(status: [ :sent, :failed ]).count
    "#{processed} / #{total}"
  end
end
