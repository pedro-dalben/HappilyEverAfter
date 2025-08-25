class Photo < ApplicationRecord
  has_one_attached :image

  def thumbnail
    processed_path = Rails.root.join('app/assets/images/processed', "thumb_#{filename}")
    if File.exist?(processed_path)
      processed_path
    else
      image.variant(resize_to_fill: [400, 400], quality: 80)
    end
  end

  def preview
    processed_path = Rails.root.join('app/assets/images/processed', "preview_#{filename}")
    if File.exist?(processed_path)
      processed_path
    else
      image.variant(resize_to_limit: [1200, 1200], quality: 85)
    end
  end

  def original
    image
  end
end
