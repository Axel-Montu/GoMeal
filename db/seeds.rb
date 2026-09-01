# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'net/http'
require 'json'

puts "Let's gooooo..."

GoMealMatch.destroy_all
User.destroy_all
Restaurant.destroy_all
PriceRange.destroy_all

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

puts response.code    # => "200"

if response.code == "200"
  puts "API successfully fetched!"
end

puts "Let's create some restaurants"

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
    end_price: end_price,
  )
  end

print "#{Restaurant.count}/20\n"

puts "Seeding done : #{Restaurant.count} restaurants created."

puts "Now let's create some users..."

User.create!(email:"test1@example.com", password: "test123")
User.create!(email:"test2@example.com", password: "test456")
User.create!(email:"test3@example.com", password: "test789")
print "#{User.count}/3\n"

puts "Seeding done : #{User.count} users created."

puts "Now let's match!"

User.all.each do |user|
  Restaurant.all.sample(3).each do |restaurant|
    GoMealMatch.create!(
      user: user,
      restaurant: restaurant,
      status: rand(0..2),
      go_meal_score: rand(0..100),
      visited: [true, false].sample
    )
    print "."
  end
end

puts ""
puts "#{GoMealMatch.count} GoMealMatches created"
puts "Now go back to work boy..."
puts "GO MEAL"

# Reviews on some of the visited matches, so the review screens have
# something to show before the rating form is built.
REVIEW_COMMENTS = [
  "Servi en douze minutes chrono, pile ce qu'il me fallait.",
  "La meilleure blanquette du quartier.",
  "Correct, mais vingt minutes d'attente.",
  nil
].freeze

GoMealMatch.where(visited: true).each_with_index do |match, index|
  # Every other one only: the rest stay available for the awaiting list.
  next if index.odd?

  Review.create!(
    go_meal_match: match,
    rating: rand(1..5),
    comment: REVIEW_COMMENTS.sample
  )
end

puts "#{Review.count} reviews created"
