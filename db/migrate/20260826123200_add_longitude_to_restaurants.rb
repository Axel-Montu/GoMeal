class AddLongitudeToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :longitude, :integer
  end
end
