class CreateGoMealMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :go_meal_matches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.integer :status
      t.integer :go_meal_score
      t.boolean :visited

      t.timestamps
    end
  end
end
