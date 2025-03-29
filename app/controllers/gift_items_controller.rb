class GiftItemsController < AdminController
  before_action :set_gift_item, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @gift_items = GiftItem.order(created_at: :desc)

    # Estatísticas para o dashboard
    @total_gift_items = GiftItem.count
    @total_value = GiftItem.sum(:price)
    @active_items = GiftItem.where(disabled: false).count
  end

  def show
  end

  def new
    @gift_item = GiftItem.new
  end

  def create
    @gift_item = GiftItem.new(gift_item_params)

    if @gift_item.save
      redirect_to gift_items_path, notice: "Item de presente criado com sucesso."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @gift_item.update(gift_item_params)
      redirect_to gift_items_path, notice: "Item de presente atualizado com sucesso."
    else
      render :edit
    end
  end

  def destroy
    @gift_item.destroy
    redirect_to gift_items_path, notice: "Item de presente excluído com sucesso."
  end

  def toggle_status
    @gift_item.update(disabled: !@gift_item.disabled)

    respond_to do |format|
      format.html { redirect_to gift_items_path, notice: "Status do item atualizado." }
      format.json { render json: { status: @gift_item.disabled ? "inactive" : "active" } }
    end
  end

  private

  def set_gift_item
    @gift_item = GiftItem.find(params[:id])
  end

  def gift_item_params
    params.require(:gift_item).permit(:name, :description, :price, :image, :disabled)
  end
end
