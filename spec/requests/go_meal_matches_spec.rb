require "rails_helper"

RSpec.describe "Match screen", type: :request do
  # 1. Two users, one restaurant, one match belonging to the first user
  let(:owner) { User.create!(email: "owner2@example.com", password: "password") }
  let(:other) { User.create!(email: "other2@example.com", password: "password") }
  let(:restaurant) do
    Restaurant.create!(
      name: "Chez Marcelle",
      address: "8 rue Rambuteau, 75003 Paris"
    )
  end
  let(:match) { GoMealMatch.create!(user: owner, restaurant: restaurant) }

  describe "GET /go_meal_matches/:id" do
    it "answers 404 on a match that belongs to someone else" do
      # 1. Signed in as the user who does not own the match
      sign_in other

      # 2. Their screen must not be readable
      get go_meal_match_path(match)

      expect(response).to have_http_status(:not_found)
    end

    it "shows the review when the match already carries one" do
      Review.create!(go_meal_match: match, rating: 4,
                     comment: "Servi en douze minutes chrono.")
      sign_in owner

      get go_meal_match_path(match)

      expect(response.body).to include("Servi en douze minutes chrono.")
    end

    it "asks for a rating when the lunch is over and unrated" do
      match.update!(expected_back_at: 1.hour.ago, visited: nil)
      sign_in owner

      get go_meal_match_path(match)

      expect(response.body).to include("Tu y es allé ?")
    end
  end
end
