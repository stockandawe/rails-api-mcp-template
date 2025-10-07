class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :email
      t.string :api_key, null: false
      t.boolean :active, default: true, null: false
      t.integer :rate_limit, default: 1000

      t.timestamps
    end

    add_index :clients, :api_key, unique: true
    add_index :clients, :email, unique: true
  end
end
