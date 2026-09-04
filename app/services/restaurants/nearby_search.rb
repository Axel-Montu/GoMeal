require "net/http"
require "json"

# Talks to Google Places (searchNearby) and nothing else: it knows how to ask
# for restaurants around the user, not when to ask or what to do with them.
#
# Deduplication relies on google_place_id (Google's stable identifier for a
# place). Two users searching the same zone share the same Restaurant rows.
#
# Every failure path logs a line prefixed by LOG_TAG with an ERROR_CODE, so a
# production incident can be diagnosed by grepping the logs for
# "[Restaurants::NearbySearch]". The codes are listed in ERROR_CODES below.
module Restaurants
  class NearbySearch
    ENDPOINT = "https://places.googleapis.com/v1/places:searchNearby".freeze

    LOG_TAG = "[Restaurants::NearbySearch]".freeze

    # Documented failure codes. All of them make #call return nil, which the
    # controller renders as the retry screen.
    ERROR_CODES = {
      missing_api_key: "GP_001_MISSING_API_KEY",       # ENV GOOGLE_PLACES_API_KEY absent
      invalid_coordinates: "GP_002_INVALID_COORDS",    # latitude/longitude nil, hors bornes ou 0,0
      invalid_radius: "GP_003_INVALID_RADIUS",         # max_walking_minutes non renseigné -> radius 0
      network_error: "GP_004_NETWORK_ERROR",           # timeout, DNS, TLS, connexion refusée
      http_error: "GP_005_HTTP_ERROR",                 # réponse HTTP non 2xx (403, 400, 429...)
      invalid_json: "GP_006_INVALID_JSON",             # corps de réponse illisible
      record_invalid: "GP_007_RECORD_INVALID",         # un Restaurant/PriceRange refuse d'être sauvé
      unexpected_error: "GP_008_UNEXPECTED_ERROR"      # tout le reste
    }.freeze

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

    # Google refuses more than 50 entries per type restriction category with a
    # 400 INVALID_ARGUMENT ("Too many types in included_types"). Our catalogue
    # holds 166 cuisines, so a user is perfectly free to select more than that:
    # we slice the selection and merge the answers instead of failing.
    MAX_TYPES_PER_REQUEST = 50

    # An empty includedTypes lifts the restriction entirely and Google starts
    # returning petrol stations and hotels, so fall back to plain restaurants.
    DEFAULT_INCLUDED_TYPES = %w[restaurant].freeze

    # Google's error payloads are small, but a truncated body keeps the logs
    # readable if that ever stops being true.
    MAX_LOGGED_BODY = 1000

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
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      api_key = ENV.fetch("GOOGLE_PLACES_API_KEY", nil)
      if api_key.blank?
        return log_failure(:missing_api_key, "GOOGLE_PLACES_API_KEY n'est pas défini dans l'environnement")
      end
      return nil unless valid_request?

      places = fetch_places(api_key)
      return nil if places.nil? # chaque lot en échec a déjà loggé sa cause

      restaurants = places.filter_map { |place| upsert_restaurant(place) }
      log_outcome(restaurants, places, started_at)

      restaurants
    rescue ActiveRecord::ActiveRecordError => e
      log_failure(:record_invalid, "échec d'écriture en base: #{e.class} #{e.message}", exception: e)
    rescue StandardError => e
      log_failure(:unexpected_error, "#{e.class}: #{e.message}", exception: e)
    end

    private

    # One call per slice of MAX_TYPES_PER_REQUEST cuisines, merged and
    # deduplicated on Google's place id (a restaurant tagged both "italian" and
    # "pizza" can come back in two slices).
    #
    # A slice that fails is logged and skipped: losing part of the cuisines is
    # better than showing the retry screen. nil — the retry screen — is only
    # returned when every single slice failed.
    def fetch_places(api_key)
      batches = included_types.each_slice(MAX_TYPES_PER_REQUEST).to_a
      succeeded = 0

      places = batches.flat_map do |batch|
        response = perform_request(api_key, batch)
        next [] if response.nil?

        succeeded += 1
        parse_places(response)
      end

      if succeeded.zero?
        Rails.logger.error("#{LOG_TAG} les #{batches.size} lot(s) de types ont échoué #{context.inspect}")
        return nil
      end

      if succeeded < batches.size
        Rails.logger.warn(
          "#{LOG_TAG} résultats partiels: #{succeeded}/#{batches.size} lot(s) de types ont abouti #{context.inspect}"
        )
      end

      places.uniq { |place| place["id"] }
    end

    def parse_places(response)
      JSON.parse(response.body).fetch("places", [])
    rescue JSON::ParserError => e
      log_failure(:invalid_json, "réponse Google illisible: #{e.message} — body=#{truncate_body(response.body)}")
      []
    end

    # Logs the outgoing call, then returns the Net::HTTP response only if it is
    # a success — otherwise it logs Google's own error body (that is where
    # REQUEST_DENIED, API_KEY_INVALID or INVALID_ARGUMENT show up) and nil.
    def perform_request(api_key, types)
      Rails.logger.info("#{LOG_TAG} requête envoyée #{context.merge(included_types: types).inspect}")

      response = post_to_google(api_key, types)
      return nil if response.nil?
      return response if response.is_a?(Net::HTTPSuccess)

      log_failure(
        :http_error,
        "Google a répondu #{response.code} #{response.message} — body=#{truncate_body(response.body)}"
      )
    end

    def log_outcome(restaurants, places, started_at)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

      if restaurants.empty?
        Rails.logger.warn(
          "#{LOG_TAG} 0 restaurant retenu (#{places.size} places renvoyées par Google) " \
          "en #{duration_ms}ms #{context.merge(included_types: included_types).inspect}"
        )
      else
        Rails.logger.info(
          "#{LOG_TAG} #{restaurants.size} restaurant(s) enregistré(s) sur #{places.size} places " \
          "en #{duration_ms}ms #{context.inspect}"
        )
      end
    end

    # Guards against the two silent misconfigurations we can detect before
    # spending a call: coordinates that never made it out of the session, and a
    # radius of 0 (user without max_walking_minutes) which Google rejects with a
    # 400 INVALID_ARGUMENT.
    def valid_request?
      if @latitude.zero? && @longitude.zero?
        log_failure(:invalid_coordinates, "latitude/longitude absentes ou nulles (0.0, 0.0)")
        return false
      end

      unless @latitude.between?(-90, 90) && @longitude.between?(-180, 180)
        log_failure(:invalid_coordinates, "coordonnées hors bornes: lat=#{@latitude} lng=#{@longitude}")
        return false
      end

      if radius_meters <= 0
        log_failure(
          :invalid_radius,
          "rayon de recherche nul — max_walking_minutes=#{@user.max_walking_minutes.inspect} " \
          "pour user_id=#{@user.id}"
        )
        return false
      end

      true
    end

    def post_to_google(api_key, types)
      uri = URI(ENDPOINT)

      request = Net::HTTP::Post.new(uri)
      request["X-Goog-Api-Key"] = api_key
      request["X-Goog-FieldMask"] = FIELD_MASK
      request["Content-Type"] = "application/json"
      request.body = request_body(types).to_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end
    rescue StandardError => e
      log_failure(:network_error, "appel HTTP impossible: #{e.class} #{e.message}", exception: e)
    end

    def request_body(types)
      {
        includedTypes: types,
        maxResultCount: MAX_RESULTS,
        locationRestriction: {
          circle: {
            center: { latitude: @latitude, longitude: @longitude },
            radius: radius_meters
          }
        }
      }
    end

    def included_types
      @included_types ||= begin
        types = @user.tags.pluck(:api_type).compact_blank.uniq
        types.presence || DEFAULT_INCLUDED_TYPES
      end
    end

    def radius_meters
      @radius_meters ||= @user.max_radius_search_meters.to_f
    end

    # A single unsavable place must not take the whole search down: we log it
    # with its google_place_id and skip it.
    def upsert_restaurant(place)
      google_place_id = place["id"]
      if google_place_id.blank?
        Rails.logger.warn("#{LOG_TAG} place ignorée: pas d'id Google — #{place.inspect}")
        return nil
      end

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
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error(
        "#{LOG_TAG} #{ERROR_CODES[:record_invalid]} place #{google_place_id} ignorée: " \
        "#{e.class} #{e.message} — attributs=#{restaurant&.attributes.inspect}"
      )
      nil
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

    # Logs the failure and returns nil, so callers can `return log_failure(...)`.
    def log_failure(code_key, message, exception: nil)
      Rails.logger.error("#{LOG_TAG} #{ERROR_CODES[code_key]} #{message} #{context.inspect}")
      Rails.logger.error("#{LOG_TAG} backtrace: #{exception.backtrace&.first(5)&.join(' | ')}") if exception
      nil
    end

    def context
      { user_id: @user&.id, lat: @latitude, lng: @longitude, radius_m: @user&.max_radius_search_meters }
    end

    def truncate_body(body)
      return "(vide)" if body.blank?

      body.to_s.truncate(MAX_LOGGED_BODY)
    end
  end
end
