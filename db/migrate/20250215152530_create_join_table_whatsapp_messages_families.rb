class CreateJoinTableWhatsappMessagesFamilies < ActiveRecord::Migration[7.0]
  def change
    create_join_table :whatsapp_messages, :families do |t|
      t.index :whatsapp_message_id
      t.index :family_id
    end
  end
end
