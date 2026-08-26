class AddTypesToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :types, :string, array: true, default: []
  end
end
