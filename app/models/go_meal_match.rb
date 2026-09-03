class GoMealMatch < ApplicationRecord
  # Radius under which we consider the user has actually reached the
  # restaurant. 150 m keeps us tolerant of urban GPS drift without matching
  # the block next door.
  NEAR_RESTAURANT_METERS = 150

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

  def awaiting_review?(current_location: nil)
    # 1. The question was never asked
    return false unless visited.nil?
    # 2. And nothing was written
    return false if review.present?

    # 3. Two paths in: lunch is over on the clock, or the user is standing
    #    at the restaurant right now
    lunch_over? || near_restaurant?(current_location)
  end

  private

  def lunch_over?
    expected_back_at.present? && expected_back_at.past?
  end

  def near_restaurant?(location)
    return false if location.blank?
    return false if restaurant.latitude.nil? || restaurant.longitude.nil?

    lat = location["latitude"] || location[:latitude]
    lon = location["longitude"] || location[:longitude]
    return false if lat.blank? || lon.blank?

    distance = Scoring::GoMealScorer.haversine_meters(
      [lat.to_f, lon.to_f],
      [restaurant.latitude, restaurant.longitude]
    )
    distance <= NEAR_RESTAURANT_METERS
  end
end
