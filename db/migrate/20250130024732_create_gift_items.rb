class CreateGiftItems < ActiveRecord::Migration[8.0]
  def change
    create_table :gift_items do |t|
      t.string :name
      t.decimal :price
      t.string :image

      t.timestamps
    end
  end
end
