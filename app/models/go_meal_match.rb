class GoMealMatch < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant
  has_one :review, dependent: :destroy
  enum :status, { pending: 0, liked: 1, rejected: 2 }
end
