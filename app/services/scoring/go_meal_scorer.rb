module Scoring
  class GoMealScorer
    RATING_MAX_PTS   = 100 / 3.0
    DISTANCE_MAX_PTS = 100 / 3.0
    PRICE_MAX_PTS    = 100 - RATING_MAX_PTS - DISTANCE_MAX_PTS

    def self.call(restaurant:, user_location:, user:)
      distance = haversine_meters(
        [user_location["latitude"].to_f, user_location["longitude"].to_f],
        [restaurant.latitude, restaurant.longitude]
      )
      rating_pts   = (restaurant.google_rating || 0) * (RATING_MAX_PTS / 5)
      distance_pts = [DISTANCE_MAX_PTS - (distance * 0.0333), 0].max
      price_pts    = price_score(restaurant.price_range, user.budget)
      (rating_pts + distance_pts + price_pts).round.clamp(0, 100)
    end

    # No price data on the restaurant: stay neutral rather than reward or penalize it.
    private_class_method def self.price_score(price_range, budget)
      return PRICE_MAX_PTS / 2 if price_range.blank? || budget.blank?

      start_price = price_range.start_price.to_f
      end_price   = price_range.end_price.to_f

      gap = if budget < start_price
        start_price - budget
      elsif budget > end_price
        budget - end_price
      else
        0
      end

      [PRICE_MAX_PTS - (gap * 1.5), 0].max
    end

    def self.haversine_meters(coord_a, coord_b)
      # https://gist.github.com/timols/5268103 reference for the formula
      lat1, lon1 = coord_a
      lat2, lon2 = coord_b

      dLat = (lat2 - lat1) * Math::PI / 180
      dLon = (lon2 - lon1) * Math::PI / 180

      a = (Math.sin(dLat / 2) *
          Math.sin(dLat / 2)) +
          (Math.cos(lat1 * Math::PI / 180) *
          Math.cos(lat2 * Math::PI / 180) *
          Math.sin(dLon / 2) * Math.sin(dLon / 2))

      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      6_371_000 * c
    end
  end
end
