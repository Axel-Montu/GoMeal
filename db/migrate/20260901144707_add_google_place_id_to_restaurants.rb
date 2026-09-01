class AddGooglePlaceIdToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :google_place_id, :string
    add_index :restaurants, :google_place_id, unique: true
  end
end
