require 'net/http'
require 'json'

class PreferencesController < ApplicationController
  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user

    unless @user.update(preferences_params)
      render :edit, status: :unprocessable_entity
      return
    end

    # 1. Ask Google first. Nothing is destroyed until we hold new data —
    #    the previous version emptied the tables, then crashed on a nil
    #    response and left the app with no restaurants at all.
    places = fetch_places
    replace_restaurants_with(places) if places

    # 2. The preferences changed either way, so the matches are rebuilt
    #    against whatever restaurants we have — the fresh ones, or the
    #    ones already in place when the API is unavailable.
    rebuild_matches_for(@user)

    if places
      redirect_to cuisines_preferences_path, notice: "Preferences updated."
    else
      redirect_to cuisines_preferences_path,
                  alert: "Préférences enregistrées. Les restaurants n'ont pas pu être actualisés (Google Places indisponible) — la sélection précédente est conservée."
    end
  end

  def cuisines
    @user = current_user
    authorize @user, :edit?
  end

  def update_cuisines
    @user = current_user
    authorize @user, :edit?
    redirect_to go_meal_matches_path
  end

  private

  def preferences_params
    params.require(:user).permit(
      :average_lunch_time_minutes,
      :preferred_start_address,
      :max_walking_minutes
    )
  end

  # Returns the places array, or nil when Google Places gave us nothing
  # usable — a quota refusal (429), an error status, or a body we cannot
  # parse. Never raises: a failed refresh must not break saving preferences.
  def fetch_places
    uri = URI('https://places.googleapis.com/v1/places:searchNearby')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['X-Goog-Api-Key'] = ENV.fetch('GOOGLE_PLACES_API_KEY')
    request['X-Goog-FieldMask'] = <<~FIELDS.split("\n").join(",")
      places.displayName.text
      places.formattedAddress
      places.location.latitude
      places.location.longitude
      places.types
      places.rating
      places.editorialSummary.text
      places.priceRange
    FIELDS
    request['Content-Type'] = 'application/json'
    request.body = {
      includedTypes: %w[
        french_restaurant indian_restaurant pizza_restaurant
        fast_food_restaurant turkish_restaurant hamburger_restaurant
        halal_restaurant mediterranean_restaurant korean_restaurant
        japanese_restaurant
      ],
      maxResultCount: 20,
      locationRestriction: {
        circle: {
          center: { latitude: 48.8642973, longitude: 2.3814914 },
          radius: 500.0
        }
      }
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("Places refresh refused: #{response.code} #{response.body.to_s.truncate(200)}")
      return nil
    end

    JSON.parse(response.body)["places"].presence
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.warn("Places refresh failed: #{e.class}")
    nil
  end

  # Swaps the whole restaurant table for the freshly fetched one. Matches and
  # price ranges follow through Restaurant's dependent: :destroy.
  def replace_restaurants_with(places)
    Restaurant.destroy_all

    places.each do |place|
      restaurant = Restaurant.create!(
        name: place.dig("displayName", "text"),
        address: place["formattedAddress"],
        latitude: place.dig("location", "latitude"),
        longitude: place.dig("location", "longitude"),
        types: place["types"],
        google_rating: place["rating"],
        editorial_summary: place.dig("editorialSummary", "text")
      )

      price_range_for(restaurant, place["priceRange"])
    end
  end

  # A place may carry no price range, or two currencies we cannot compare —
  # both mean no price range rather than a crash.
  def price_range_for(restaurant, range)
    return if range.blank?

    start_price = range.dig("startPrice", "units")
    end_price   = range.dig("endPrice", "units")
    currency    = range.dig("startPrice", "currencyCode")
    return unless currency && currency == range.dig("endPrice", "currencyCode")

    PriceRange.create!(
      restaurant: restaurant,
      currency: currency,
      start_price: start_price,
      end_price: end_price
    )
  end

  # Only this user's matches — the previous version wiped every user's.
  def rebuild_matches_for(user)
    user.go_meal_matches.destroy_all

    Restaurant.find_each do |restaurant|
      user.go_meal_matches.create!(restaurant: restaurant, go_meal_score: rand(0..100))
    end
  end
end
