class CreatePriceRanges < ActiveRecord::Migration[8.1]
  def change
    create_table :price_ranges do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :currency
      t.integer :start_price
      t.integer :end_price

      t.timestamps
    end
  end
end
