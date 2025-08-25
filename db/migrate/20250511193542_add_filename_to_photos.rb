class AddFilenameToPhotos < ActiveRecord::Migration[8.0]
  def change
    add_column :photos, :filename, :string
  end
end
