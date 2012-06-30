class AddRdioTokenSecretToUsers < ActiveRecord::Migration
  def change
    add_column :users, :rdio_secret, :string
  end
end
