# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


puts "Let's gooooo..."

GoMealMatch.destroy_all
User.destroy_all
Restaurant.destroy_all


Restaurant.create!(name: "Chez Justine", address: "96 Rue Oberkampf, 75011 Paris")
Restaurant.create!(name: "Le Servan", address: "32 Rue Saint-Maur, 75011 Paris")
Restaurant.create!(name: "Clamato", address: "80 Rue de Charonne, 75011 Paris")
Restaurant.create!(name: "Septime", address: "81 Rue de Charonne, 75011 Paris")
Restaurant.create!(name: "Le Chateaubriand", address: "129 Avenue Parmentier, 75011 Paris")
Restaurant.create!(name: "Bistrot Paul Bert", address: "18 Rue Paul Bert, 75011 Paris")
Restaurant.create!(name: "Le Bistrot du Peintre", address: "116 Avenue Ledru-Rollin, 75011 Paris")
Restaurant.create!(name: "Astier", address: "44 Rue Jean-Pierre Timbaud, 75011 Paris")
Restaurant.create!(name: "Aux Deux Amis", address: "45 Rue Oberkampf, 75011 Paris")
Restaurant.create!(name: "Le Villaret", address: "13 Rue Ternaux, 75011 Paris")
print "#{Restaurant.count}/10\n"

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
