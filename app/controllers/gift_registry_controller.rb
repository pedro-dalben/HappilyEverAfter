class GiftRegistryController < ApplicationController
  def index
    @gift_items = GiftItem.all
  end

  def add_to_cart
    id = params[:id].to_i
    session[:cart] ||= []
    session[:cart] << id

    respond_to do |format|
      format.html { redirect_to gift_registry_path, notice: "Item adicionado ao carrinho." }
      format.json { render json: { cart_count: session[:cart].size }, status: :ok }
    end
  end

  def cart
    @cart_items = []
    @total = 0

    if session[:cart].present?
      item_counts = Hash.new(0)
      session[:cart].each { |id| item_counts[id] += 1 }

      item_counts.each do |id, quantity|
        gift_item = GiftItem.find_by(id: id)
        if gift_item
          @cart_items << {
            item: gift_item,
            quantity: quantity,
            subtotal: gift_item.price * quantity
          }
          @total += gift_item.price * quantity
        end
      end
    end
  end

  def remove_from_cart
    id = params[:id].to_i
    session[:cart].delete_at(session[:cart].index(id) || session[:cart].length)

    redirect_to cart_path, notice: "Item removido do carrinho."
  end

  def checkout
    @cart_items = []
    @total = 0

    if session[:cart].present?
      item_counts = Hash.new(0)
      session[:cart].each { |id| item_counts[id] += 1 }

      item_counts.each do |id, quantity|
        gift_item = GiftItem.find_by(id: id)
        if gift_item
          @cart_items << {
            item: gift_item,
            quantity: quantity,
            subtotal: gift_item.price * quantity
          }
          @total += gift_item.price * quantity
        end
      end
    end
  end

  def buy_now
    id = params[:id].to_i
    session[:cart] = [id]

    redirect_to checkout_path
  end

  def empty_cart
    session[:cart] = []
    redirect_to cart_path, notice: "Carrinho esvaziado."
  end
end
