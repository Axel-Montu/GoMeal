module Scoring
  class GoMealScorer
    def self.call(restaurant:, user_location:)
      distance = haversine_meters(
        [user_location["latitude"].to_f, user_location["longitude"].to_f],
        [restaurant.latitude, restaurant.longitude]
      )
      rating_pts   = (restaurant.google_rating || 0) * 10
      distance_pts = [50 - (distance * 0.05), 0].max
      (rating_pts + distance_pts).round.clamp(0, 100)
    end

    private_class_method def self.haversine_meters(coord_a, coord_b)
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
