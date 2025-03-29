module Admin
  class GiftsController < AdminController
    before_action :set_gift, only: [:show, :edit, :update, :update_status]

    def index
      @orders = Order.includes(:family, :order_items => :gift_item).order(created_at: :desc)

      # Filtrar por status, se especificado
      if params[:status].present?
        @orders = @orders.where(status: params[:status])
      end

      # Estatísticas gerais
      @total_paid = Order.where(status: "paid").sum(:total)
      @total_pending = Order.where(status: "pending").sum(:total)
      @total_orders = Order.count
      @paid_orders_count = Order.where(status: "paid").count
      @pending_orders_count = Order.where(status: "pending").count
    end

    def show
      @order = Order.includes(:family, :order_items => :gift_item).find(params[:id])
    end

    def edit
    end

    def update
      if @gift.update(gift_params)
        redirect_to admin_gift_path(@gift), notice: "Presente atualizado com sucesso."
      else
        render :edit
      end
    end

    def update_status
      @order = Order.find(params[:id])

      if @order.update(status: params[:status])
        redirect_to admin_gift_path(@order), notice: "Status do pedido atualizado com sucesso."
      else
        redirect_to admin_gift_path(@order), alert: "Erro ao atualizar status."
      end
    end

    private

    def set_gift
      @gift = GiftItem.find(params[:id])
    end

    def gift_params
      params.require(:gift_item).permit(:name, :description, :price, :image, :status)
    end
  end
end
