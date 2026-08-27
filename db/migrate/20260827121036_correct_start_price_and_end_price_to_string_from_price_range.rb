class CorrectStartPriceAndEndPriceToStringFromPriceRange < ActiveRecord::Migration[8.1]
  def change
    change_column :price_ranges, :start_price, :string
    change_column :price_ranges, :end_price, :string
  end
end
