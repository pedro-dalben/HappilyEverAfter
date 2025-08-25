namespace :photos do
  desc "Processa as fotos do casamento e cria versões otimizadas"
  task process: :environment do
    require 'image_processing/vips'

    wedding_photos_dir = Rails.root.join('app/assets/images/wedding_photos')
    processed_dir = Rails.root.join('app/assets/images/processed')

    FileUtils.mkdir_p(processed_dir)

    Dir.glob(File.join(wedding_photos_dir, '*')).each do |file|
      next unless File.file?(file)

      begin
        filename = File.basename(file)
        sanitized_filename = filename.gsub(/\s+/, '_')

        # Cria versões otimizadas
        thumbnail = ImageProcessing::Vips
          .source(file)
          .resize_to_fill(400, 400)
          .saver(quality: 80)
          .call

        preview = ImageProcessing::Vips
          .source(file)
          .resize_to_limit(1200, 1200)
          .saver(quality: 85)
          .call

        # Salva as versões processadas
        FileUtils.cp(thumbnail.path, File.join(processed_dir, "thumb_#{sanitized_filename}"))
        FileUtils.cp(preview.path, File.join(processed_dir, "preview_#{sanitized_filename}"))

        # Verifica se já existe um registro da foto
        photo = Photo.find_or_initialize_by(filename: sanitized_filename)

        # Atualiza ou cria o registro
        photo.update!(
          description: filename.gsub(/\.[^.]*$/, ''),
          category: 'wedding'
        )

        # Anexa a imagem original se ainda não estiver anexada
        unless photo.image.attached?
          photo.image.attach(io: File.open(file), filename: sanitized_filename)
        end

        puts "Processado: #{filename}"
      rescue => e
        puts "Erro ao processar #{filename}: #{e.message}"
      end
    end

    puts "Processamento concluído!"
  end
end
