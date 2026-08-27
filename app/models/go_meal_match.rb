class GoMealMatch < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant
  enum :status, { pending: 0, liked: 1, rejected: 2 }
end
