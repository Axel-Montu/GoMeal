class ChangeTypeOfStartPriceAndEndPriceToPriceRanges < ActiveRecord::Migration[8.1]
  def change
    change_column :price_ranges, :start_price, :float
    change_column :price_ranges, :end_price, :float
  end
end
