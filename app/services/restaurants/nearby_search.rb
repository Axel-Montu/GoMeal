require "net/http"
require "json"

# Talks to Google Places (searchNearby) and nothing else: it knows how to ask
# for restaurants around the user, not when to ask or what to do with them.
#
# Deduplication relies on google_place_id (Google's stable identifier for a
# place). Two users searching the same zone share the same Restaurant rows.
module Restaurants
  class NearbySearch
    ENDPOINT = "https://places.googleapis.com/v1/places:searchNearby".freeze

    FIELD_MASK = %w[
      places.id
      places.displayName.text
      places.formattedAddress
      places.location.latitude
      places.location.longitude
      places.types
      places.rating
      places.editorialSummary.text
      places.priceRange
    ].join(",").freeze

    MAX_RESULTS = 20

    def self.call(user:, latitude:, longitude:)
      new(user, latitude, longitude).call
    end

    def initialize(user, latitude, longitude)
      @user = user
      @latitude = latitude.to_f
      @longitude = longitude.to_f
    end

    # Returns an array of Restaurant records on success (possibly empty).
    # Returns nil when the Google Places API is unreachable or answers with
    # something we cannot parse — callers use that to render a retry UI
    # instead of silently wiping the user's existing matches.
    def call
      response = post_to_google(ENV.fetch("GOOGLE_PLACES_API_KEY"))
      return nil unless response.is_a?(Net::HTTPSuccess)

      places = JSON.parse(response.body).fetch("places", [])
      places.filter_map { |place| upsert_restaurant(place) }
    rescue JSON::ParserError
      nil
    end

    private

    def post_to_google(api_key)
      uri = URI(ENDPOINT)

      request = Net::HTTP::Post.new(uri)
      request["X-Goog-Api-Key"] = api_key
      request["X-Goog-FieldMask"] = FIELD_MASK
      request["Content-Type"] = "application/json"
      request.body = request_body.to_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end
    rescue StandardError
      nil
    end

    def request_body
      {
        includedTypes: @user.tags.pluck(:api_type).compact_blank,
        maxResultCount: MAX_RESULTS,
        locationRestriction: {
          circle: {
            center: { latitude: @latitude, longitude: @longitude },
            radius: @user.max_radius_search_meters.to_f
          }
        }
      }
    end

    def upsert_restaurant(place)
      google_place_id = place["id"]
      return nil if google_place_id.blank?

      restaurant = Restaurant.find_or_initialize_by(google_place_id: google_place_id)
      restaurant.assign_attributes(
        name: place.dig("displayName", "text"),
        address: place["formattedAddress"],
        latitude: place.dig("location", "latitude"),
        longitude: place.dig("location", "longitude"),
        types: place["types"],
        google_rating: place["rating"],
        editorial_summary: place.dig("editorialSummary", "text")
      )
      restaurant.save!
      upsert_price_range(restaurant, place["priceRange"])
      restaurant
    end

    def upsert_price_range(restaurant, price_range)
      return if price_range.blank?

      start_price = price_range.dig("startPrice", "units")
      end_price   = price_range.dig("endPrice", "units")
      currency    = price_range.dig("startPrice", "currencyCode")
      return if start_price.blank? || end_price.blank?

      pr = restaurant.price_range || restaurant.build_price_range
      pr.update!(currency: currency, start_price: start_price, end_price: end_price)
    end
  end
end
