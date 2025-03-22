class AddCpfCnpjToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :customer_cpf_cnpj, :string
  end
end
