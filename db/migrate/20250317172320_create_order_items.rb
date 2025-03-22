class CreateOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :gift_item, null: false, foreign_key: true
      t.integer :quantity, default: 1
      t.decimal :price, precision: 8, scale: 2

      t.timestamps
    end
  end
end
