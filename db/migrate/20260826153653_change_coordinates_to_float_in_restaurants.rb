class ChangeCoordinatesToFloatInRestaurants < ActiveRecord::Migration[8.1]
  def change
    change_column :restaurants, :latitude, :float
    change_column :restaurants, :longitude, :float
  end
end
