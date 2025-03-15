class AddConfirmedStatusToFamilies < ActiveRecord::Migration[7.0]
  def change
    add_column :families, :confirmed, :boolean, default: false
  end
end
