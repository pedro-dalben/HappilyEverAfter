class AddErrorMessageToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :error_message, :text
  end
end
