require "rails_helper"

RSpec.describe GoMealMatch, type: :model do
  it "is valid with a user and a restaurant" do
    # 1. Build the two records a match depends on
    user = User.new(email: "smoke@example.com", password: "password")
    restaurant = Restaurant.new(
      name: "L'Atelier Verde",
      address: "14 rue des Petits-Champs, 75002 Paris"
    )

    # 2. Build the match itself. `new` and not `create`: checking validity
    #    does not need the database.
    match = GoMealMatch.new(user: user, restaurant: restaurant)

    # 3. Both belongs_to are satisfied, so the match is valid
    expect(match).to be_valid
  end
end
