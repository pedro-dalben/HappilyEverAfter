class HomeController < ApplicationController
  def index
    images_dir = Rails.root.join("app", "assets", "images", "carrosel")
    # Grab all files in /carrosel (any name or type) and map to filenames
    @carousel_images = Dir.glob("#{images_dir}/*").map { |f| File.basename(f) }
  end
end
