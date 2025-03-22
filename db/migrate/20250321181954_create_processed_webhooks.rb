class CreateProcessedWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :processed_webhooks do |t|
      t.string :event_id, null: false
      t.text :payload

      t.timestamps
    end

    add_index :processed_webhooks, :event_id, unique: true
  end
end
