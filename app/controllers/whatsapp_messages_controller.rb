class WhatsappMessagesController < AdminController
  def new
    @message = WhatsappMessage.new
    # Lista todas as famílias para seleção
    @recipients = Family.all
  end

  def create
    permitted_params = message_params
    family_ids = permitted_params.delete(:family_ids)

    if family_ids.blank? || family_ids.reject(&:blank?).empty?
      @message = WhatsappMessage.new(permitted_params)
      @message.errors.add(:base, "Selecione pelo menos uma família para enviar a mensagem")
      @recipients = Family.all
      return render :new
    end

    family_ids = family_ids.reject(&:blank?)
    @message = WhatsappMessage.new(permitted_params)
    @message.families = Family.where(id: family_ids)
    @message.total_count = family_ids.size
    @message.sent_count = 0
    @message.failed_count = 0
    @message.status = WhatsappMessage::STATUS_PENDING

    if @message.save
      # Usamos perform_in para dar tempo para a transação do banco de dados ser completada
      # Aumentando para 5 segundos para garantir que a transação seja confirmada
      WhatsappMessageWorker.perform_in(5.seconds, @message.id)
      redirect_to whatsapp_messages_path, notice: "Mensagem agendada para envio para #{@message.total_count} famílias."
    else
      @recipients = Family.all
      render :new
    end
  end

  def index
    @messages = WhatsappMessage.order(created_at: :desc)
  end

  def show
    @message = WhatsappMessage.find(params[:id])
  end

  private

  def message_params
    # Permite a imagem e o array de family_ids
    params.require(:whatsapp_message).permit(:content, :image, family_ids: [])
  end
end
