class AddGoogleRatingToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :google_rating, :float
  end
end
