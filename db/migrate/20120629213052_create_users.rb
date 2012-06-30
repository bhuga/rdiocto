class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :github_key
      t.string :rdio_key
      t.string :github_username
      t.string :rdio_username
    end
  end
end
