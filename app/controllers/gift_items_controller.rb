class GiftItemsController < ApplicationController
  layout "admin"

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
    if @gift_item.save
      redirect_to gift_items_path, notice: "Gift item created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @gift_item.update(gift_item_params)
      redirect_to gift_items_path, notice: "Gift item updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @gift_item.destroy

    respond_to do |format|
      format.html { head :no_content }
      format.json { render json: { message: "Gift item deleted successfully." }, status: :ok }
    end
  end

  private

  def set_gift_item
    @gift_item = GiftItem.find(params[:id])
  end

  def gift_item_params
    params.require(:gift_item).permit(:name, :price, :image)
  end
end
