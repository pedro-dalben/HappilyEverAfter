class AddDisabledToGiftItems < ActiveRecord::Migration[8.0]
  def change
    add_column :gift_items, :disabled, :boolean, default: false, null: false
  end
end
