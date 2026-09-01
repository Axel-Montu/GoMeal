class AddExpectedBackAtToGoMealMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :go_meal_matches, :expected_back_at, :datetime
    add_index :go_meal_matches, :expected_back_at

    # `visited` becomes a three-state answer: nil = never asked, true = I went,
    # false = I did not. The old default made the first two indistinguishable.
    change_column_default :go_meal_matches, :visited, from: false, to: nil
    change_column_null :go_meal_matches, :visited, true
  end
end
