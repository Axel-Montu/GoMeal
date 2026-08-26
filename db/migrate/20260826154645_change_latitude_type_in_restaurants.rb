class ChangeLatitudeTypeInRestaurants < ActiveRecord::Migration[8.1]
  def change
    change_column :restaurants, :latitude, :float
  end
end
