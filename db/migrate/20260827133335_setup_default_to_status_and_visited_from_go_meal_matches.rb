class SetupDefaultToStatusAndVisitedFromGoMealMatches < ActiveRecord::Migration[8.1]
  def change
    change_column :go_meal_matches, :status, :integer, default: 0
    change_column :go_meal_matches, :visited, :boolean, default: false
  end
end
