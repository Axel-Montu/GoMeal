class Review < ApplicationRecord
  belongs_to :go_meal_match

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 500 }
end
