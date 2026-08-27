class ChangeTypeOfLatitudeAndLongitudeToRestaurants < ActiveRecord::Migration[8.1]
  def change
    change_column :restaurants, :longitude, :float
    change_column :restaurants, :latitude, :float
  end
end
