class Restaurant < ApplicationRecord
  has_many :go_meal_matches, dependent: :destroy
  has_one :price_range, dependent: :destroy

  validates :name, presence: true
  validates :address, presence: true
end
