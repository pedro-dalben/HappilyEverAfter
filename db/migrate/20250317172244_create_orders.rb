class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :family, foreign_key: true
      t.string :status, default: "pending"
      t.decimal :total, precision: 8, scale: 2
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone
      t.string :asaas_payment_id
      t.string :asaas_customer_id
      t.string :payment_method
      t.string :payment_url
      t.text :payment_data, default: "{}"

      t.timestamps
    end
  end
end
