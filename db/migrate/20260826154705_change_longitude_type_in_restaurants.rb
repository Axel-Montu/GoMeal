class ChangeLongitudeTypeInRestaurants < ActiveRecord::Migration[8.1]
  def change
    change_column :restaurants, :longitude, :float
  end
end
