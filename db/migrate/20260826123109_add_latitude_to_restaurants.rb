class AddLatitudeToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :latitude, :integer
  end
end
