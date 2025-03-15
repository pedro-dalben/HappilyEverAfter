class AddConfirmedToMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :members, :confirmed, :boolean, default: false
  end
end
