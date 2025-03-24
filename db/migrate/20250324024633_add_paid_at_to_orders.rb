class AddPaidAtToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :paid_at, :datetime
  end
end
