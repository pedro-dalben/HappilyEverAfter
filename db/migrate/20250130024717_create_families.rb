class CreateFamilies < ActiveRecord::Migration[7.0]
  def change
    create_table :families do |t|
      t.string :name
      t.string :phone
      t.string :token

      t.timestamps
    end
  end
end
