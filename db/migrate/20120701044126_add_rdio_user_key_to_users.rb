class AddRdioUserKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :rdio_user_key, :string
  end
end
