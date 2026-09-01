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
    if @user.update(preferences_params)
      api_call
      Restaurant.all.each do |restaurant|
        score = rand(0..100)
        @match = GoMealMatch.new(go_meal_score: score)
        @match.user = current_user
        @match.restaurant = restaurant
        @match.save
      end
      redirect_to cuisines_preferences_path, notice: "Preferences updated."
    else
      render :edit, status: :unprocessable_entity
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

  def api_call
    GoMealMatch.destroy_all
    Restaurant.destroy_all

    uri = URI('https://places.googleapis.com/v1/places:searchNearby')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['X-Goog-Api-Key'] = ENV['GOOGLE_PLACES_API_KEY']
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
    request.body = '{
      "includedTypes": ["french_restaurant",
      "indian_restaurant",
      "pizza_restaurant",
      "fast_food_restaurant",
      "turkish_restaurant",
      "hamburger_restaurant",
      "halal_restaurant",
      "mediterranean_restaurant",
      "korean_restaurant",
      "japanese_restaurant"],
        "maxResultCount": 20,
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": 48.8642973,
              "longitude": 2.3814914},
            "radius": 500.0
            }
          }
    }'

    response = http.request(request)
    data = JSON.parse(response.body)

    puts response

    if response == '200'
      puts 'API fetched successfully'
    else
      puts 'Something went wrong with API'
    end

    data["places"].each do |place|
      name = place["displayName"]["text"]
      address = place["formattedAddress"]
      latitude = place["location"]["latitude"]
      longitude = place["location"]["longitude"]
      types = place["types"]
      rating = place["rating"]

      if place["editorialSummary"]
        editorial_summary = place["editorialSummary"]["text"]
      end

      new_restaurant = Restaurant.new(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        types: types,
        google_rating: rating,
        editorial_summary: editorial_summary
      )

      new_restaurant.save!

      if place["priceRange"]["startPrice"]["currencyCode"] == place["priceRange"]["endPrice"]["currencyCode"]
        currency = place["priceRange"]["startPrice"]["currencyCode"]
        start_price = place["priceRange"]["startPrice"]["units"]
        end_price = place["priceRange"]["endPrice"]["units"]
      end

      PriceRange.create!(
        restaurant_id: new_restaurant.id,
        currency: currency,
        start_price: start_price,
        end_price: end_price
      )
    end
  end
end
