require "rails_helper"
require "webmock/rspec"

RSpec.describe "Preferences", type: :request do
  let(:user) { User.create!(email: "prefs@example.com", password: "password") }

  # The restaurant already in place before the user saves their preferences.
  # It is the one that used to disappear.
  let!(:existing) do
    Restaurant.create!(name: "Chez Momo", address: "5 Rue Léon Frot, 75011 Paris")
  end

  let(:places_url) { "https://places.googleapis.com/v1/places:searchNearby" }
  let(:preferences) { { user: { average_lunch_time_minutes: 65, max_walking_minutes: 15 } } }

  describe "PATCH /preferences when Google Places refuses" do
    before do
      # The quota answer that emptied the database: the tables were wiped
      # before the call, and the nil body then raised NoMethodError.
      stub_request(:post, places_url).to_return(
        status: 429,
        body: { error: { code: 429, status: "RESOURCE_EXHAUSTED" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      sign_in user
    end

    it "keeps the restaurants already in place" do
      expect { patch preferences_path, params: preferences }
        .not_to change(Restaurant, :count)

      expect(existing.reload).to be_persisted
    end

    it "still saves the preferences and redirects instead of crashing" do
      patch preferences_path, params: preferences

      expect(response).to redirect_to(cuisines_preferences_path)
      expect(flash[:alert]).to be_present
      expect(user.reload.average_lunch_time_minutes).to eq(65)
    end
  end

  describe "PATCH /preferences when Google Places answers" do
    before do
      stub_request(:post, places_url).to_return(
        status: 200,
        body: {
          places: [{
            displayName: { text: "Delhi Bazaar" },
            formattedAddress: "71 Rue Servan, 75011 Paris",
            location: { latitude: 48.8632, longitude: 2.3830 },
            types: ["indian_restaurant"],
            rating: 4.8
          }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      sign_in user
    end

    it "replaces the restaurants with the fresh ones" do
      patch preferences_path, params: preferences

      expect(Restaurant.pluck(:name)).to eq(["Delhi Bazaar"])
    end

    it "rebuilds this user's matches against them" do
      patch preferences_path, params: preferences

      expect(user.go_meal_matches.count).to eq(1)
    end
  end
end
