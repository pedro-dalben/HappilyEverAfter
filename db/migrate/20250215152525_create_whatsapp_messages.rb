class CreateWhatsappMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :whatsapp_messages do |t|
      t.text :content
      t.string :status, default: "pending", null: false
      t.integer :sent_count, default: 0, null: false
      t.integer :failed_count, default: 0, null: false
      t.integer :total_count, default: 0, null: false

      t.timestamps
    end
  end
end
