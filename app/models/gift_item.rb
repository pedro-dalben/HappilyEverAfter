class GiftItem < ApplicationRecord
  has_one_attached :image
  has_many :order_items, dependent: :restrict_with_error

  validate :image_constraints

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  private

  def image_constraints
    return unless image.attached?

    errors.add(:image, "must be a PNG, JPEG, or GIF") unless image.blob.content_type.in?(%w[image/png image/jpeg image/gif])
    errors.add(:image, "must be smaller than 5 MB") if image.blob.byte_size >= 5.megabytes
  end

  scope :active, -> { where(disabled: false) }
end
