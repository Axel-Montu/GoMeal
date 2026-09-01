class AddColumnBudgetToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :budget, :integer
  end
end
