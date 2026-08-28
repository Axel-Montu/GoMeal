require "rails_helper"

RSpec.describe "Itineraries", type: :request do
  # 1. Two users, one restaurant, one match belonging to the first user
  let(:owner) { User.create!(email: "owner@example.com", password: "password") }
  let(:other) { User.create!(email: "other@example.com", password: "password") }
  let(:restaurant) do
    Restaurant.create!(
      name: "L'Atelier Verde",
      address: "14 rue des Petits-Champs, 75002 Paris",
      latitude: 48.8665,
      longitude: 2.3395
    )
  end
  let(:match) { GoMealMatch.create!(user: owner, restaurant: restaurant) }
  let(:position) { { start_latitude: 48.8642, start_longitude: 2.3814 } }

   describe "POST /go_meal_matches/:id/itinerary" do
        it "answers with the address of the itinerary page" do
      # 1. The browser calls this with fetch, so the answer is JSON,
      #    not an HTTP redirect
      sign_in owner

      post go_meal_match_itinerary_path(match), params: position

      expect(JSON.parse(response.body)["redirect_to"])
        .to eq(go_meal_match_itinerary_path(match))
    end

    it "never accepts a position for a match belonging to someone else" do
      # 2. The other user must not be able to start a trip on this match
      sign_in other

      post go_meal_match_itinerary_path(match), params: position

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /go_meal_matches/:id/itinerary" do
    it "shows the restaurant once a position has been posted" do
      # 3. Post first: the position lives in the session, not in the database
      sign_in owner
      post go_meal_match_itinerary_path(match), params: position

      get go_meal_match_itinerary_path(match)

      # ERB escapes the apostrophe, so we compare against the escaped name
      expect(response.body).to include(CGI.escapeHTML(restaurant.name))    end

    it "sends the user back when no position was posted" do
      # 4. Landing here directly, with nothing in the session
      sign_in owner

      get go_meal_match_itinerary_path(match)

      expect(response).to redirect_to(go_meal_match_path(match))
    end
  end
end
