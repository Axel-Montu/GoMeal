class Restaurant < ApplicationRecord
  has_many :go_meal_matches, dependent: :destroy

  validates :name, presence: true
  validates :address, presence: true

end
