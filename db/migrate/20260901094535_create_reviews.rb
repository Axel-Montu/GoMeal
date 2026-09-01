class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      # A lunch carries at most one review. The unique index is what enforces
      # it, since a model validation loses the race between two requests.
      t.references :go_meal_match, null: false, foreign_key: true,
                   index: { unique: true }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end
  end
end
