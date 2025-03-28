class GiftItemsController < AdminController
  before_action :set_gift_item, only: [ :show, :edit, :update, :destroy ]

  def index
    @gift_items = GiftItem.all
  end

  def show
  end

  def new
    @gift_item = GiftItem.new
  end

  def create
    @gift_item = GiftItem.new(gift_item_params)
    Rails.logger.info "Criando GiftItem com parâmetros: #{gift_item_params.inspect}"
    if @gift_item.save
      redirect_to gift_items_path, flash: { admin_notice: "Gift item created successfully." }
    else
      render :new
    end
  end

  def edit
  end

  def update
    Rails.logger.info "Atualizando GiftItem com parâmetros: #{gift_item_params.inspect}"
    if @gift_item.update(gift_item_params)
      redirect_to gift_items_path, flash: { admin_notice: "Gift item updated successfully." }
    else
      render :edit
    end
  end

  def destroy
    begin
      if @gift_item.destroy
        respond_to do |format|
          format.html { redirect_to gift_items_path, flash: { admin_notice: "Item de presente excluído com sucesso." }, status: :see_other }
          format.json { head :no_content }
        end
      else
        error_messages = @gift_item.errors.full_messages.join(", ")
        if error_messages.include?("dependent order items exist")
          error_messages = "Este item não pode ser excluído pois existem pedidos associados a ele"
        end
        Rails.logger.error "Falha ao excluir gift_item #{@gift_item.id}: #{error_messages}"
        respond_to do |format|
          format.html { redirect_to gift_items_path, flash: { admin_alert: error_messages }, status: :see_other }
          format.json { render json: { error: error_messages }, status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::DeleteRestrictionError => e
      Rails.logger.error "DeleteRestrictionError ao excluir gift_item #{@gift_item.id}: #{e.message}"
      respond_to do |format|
        format.html { redirect_to gift_items_path, flash: { admin_alert: "Não é possível excluir este item pois ele está associado a pedidos." }, status: :see_other }
        format.json { render json: { error: "Não é possível excluir este item pois ele está associado a pedidos." }, status: :unprocessable_entity }
      end
    rescue => e
      Rails.logger.error "Erro inesperado ao excluir gift_item #{@gift_item.id}: #{e.message}"
      respond_to do |format|
        format.html { redirect_to gift_items_path, flash: { admin_alert: "Erro inesperado ao excluir o item." }, status: :see_other }
        format.json { render json: { error: "Erro inesperado ao excluir o item." }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_gift_item
    @gift_item = GiftItem.find(params[:id])
  end

  def gift_item_params
    params.require(:gift_item).permit(:name, :price, :image, :disabled)
  end
end
