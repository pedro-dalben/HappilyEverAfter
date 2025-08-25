class HomeController < ApplicationController
  def index
    # Carrossel de imagens
    @carousel_images = Dir.glob(Rails.root.join('app/assets/images/carrosel/*')).map { |f| File.basename(f) }

    # Fotos do casamento (apenas as versões processadas)
    @wedding_photos = Dir.glob(Rails.root.join('app/assets/images/processed/thumb_*')).map do |file|
      filename = File.basename(file).gsub('thumb_', '')
      {
        filename: filename,
        thumbnail: ActionController::Base.helpers.asset_path("processed/thumb_#{filename}"),
        preview: ActionController::Base.helpers.asset_path("processed/preview_#{filename}")
      }
    end
  end
end
