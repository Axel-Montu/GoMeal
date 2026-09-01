class GoMealMatch < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant
  has_one :review, dependent: :destroy
  enum :status, { pending: 0, liked: 1, rejected: 2 }
  # A lunch waits for its review once the user is expected to be back, as long
  # as they have neither answered nor written one. `where.missing` returns the
  # records that have no associated review.
  scope :awaiting_review, -> {
    where(visited: nil)
      .where("expected_back_at <= ?", Time.current)
      .where.missing(:review)
  }

  def awaiting_review?
    # 1. The question was never asked
    return false unless visited.nil?
    # 2. The user never walked there
    return false if expected_back_at.nil?
    # 3. Lunch is not over yet
    return false if expected_back_at.future?

    # 4. And nothing was written
    review.nil?
  end
end
