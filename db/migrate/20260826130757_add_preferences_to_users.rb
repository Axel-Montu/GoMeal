class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :average_lunch_time_minutes, :integer
    add_column :users, :preferred_start_address, :string
  end
end
