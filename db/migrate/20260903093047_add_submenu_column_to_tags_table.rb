class AddSubmenuColumnToTagsTable < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :submenu, :string
  end
end
