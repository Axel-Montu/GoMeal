class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :api_type
      t.string :frontend_type
      t.string :backend_tag
      t.string :frontend_tag

      t.timestamps
    end
  end
end
