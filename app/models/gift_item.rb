class GiftItem < ApplicationRecord
  has_one_attached :image
  has_many :order_items, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(disabled: false) }
end
