class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :gift_item

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  after_save :update_order_total
  after_destroy :update_order_total

  def subtotal
    price * quantity
  end

  private

  def update_order_total
    order.update_total
  end
end
