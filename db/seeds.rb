# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'csv'

puts "Let's gooooo..."

GoMealMatch.destroy_all
User.destroy_all
Restaurant.destroy_all
PriceRange.destroy_all
Tag.destroy_all

puts "Now let's create some tags..."

CSV.foreach(Rails.root.join("db/data/restaurant_types.csv"), headers: true) do |row|
  Tag.create!(
    api_type: row["api_type"],
    frontend_type: row["frontend_type"],
    backend_tag: row["backend_tag"],
    frontend_tag: row["frontend_tag"]
  )
end

puts "Seeding done : #{Tag.count} tags created."

puts "Fetching a Paris fixture set of restaurants for dev (via Restaurants::NearbySearch)..."

# A throw-away user carrying the search knobs the real service expects.
# Deleted right after — we keep the restaurants, not the technical user.
dev_user = User.create!(email: "seed@example.com", password: "seedpassword", max_walking_minutes: 10)
dev_user.tags = Tag.where(api_type: %w[
  french_restaurant indian_restaurant pizza_restaurant fast_food_restaurant
  turkish_restaurant hamburger_restaurant halal_restaurant
  mediterranean_restaurant korean_restaurant japanese_restaurant
])

Restaurants::NearbySearch.call(user: dev_user, latitude: 48.8642973, longitude: 2.3814914)

dev_user.destroy

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
