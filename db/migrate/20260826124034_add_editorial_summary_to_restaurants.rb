class AddEditorialSummaryToRestaurants < ActiveRecord::Migration[8.1]
  def change
    add_column :restaurants, :editorial_summary, :text
  end
end
