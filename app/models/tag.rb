class Tag < ApplicationRecord
  has_many :user_tags, dependent: :destroy
  has_many :users, through: :user_tags

  def display_name
    frontend_type.sub(/\s+restaurant\z/i, "")
  end
end
