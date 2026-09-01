class AddMaxWalkingMinutesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :max_walking_minutes, :integer
  end
end
