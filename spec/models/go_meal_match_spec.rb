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
  describe "#awaiting_review?" do
    def build_match(attributes = {})
      user = User.new(email: "await@example.com", password: "password")
      restaurant = Restaurant.new(name: "Pho Mekong",
                                  address: "12 rue du Caire, 75002 Paris")
      GoMealMatch.new({ user: user, restaurant: restaurant }.merge(attributes))
    end

    it "waits for a review once the user is expected to be back" do
      match = build_match(visited: nil, expected_back_at: 1.hour.ago)

      expect(match.awaiting_review?).to be true
    end

    it "does not wait while lunch is still running" do
      match = build_match(visited: nil, expected_back_at: 20.minutes.from_now)

      expect(match.awaiting_review?).to be false
    end

    it "does not wait when the itinerary was never opened" do
      match = build_match(visited: nil, expected_back_at: nil)

      expect(match.awaiting_review?).to be false
    end

    it "stops waiting once the user said they did not go" do
      match = build_match(visited: false, expected_back_at: 1.hour.ago)

      expect(match.awaiting_review?).to be false
    end
  end
end
