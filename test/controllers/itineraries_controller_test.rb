require "test_helper"

class ItinerariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "walker@example.com",
      password: "password",
      average_lunch_time_minutes: 30
    )
    @restaurant = Restaurant.create!(
      name: "Brasserie Martin",
      address: "24 Rue Saint-Ambroise, 75011 Paris",
      latitude: 48.8615,
      longitude: 2.3785
    )
    @match = GoMealMatch.create!(user: @user, restaurant: @restaurant)

    # 1. Answer for OpenRouteService: 240 seconds of walking, 286 metres
    stub_request(:post, %r{api\.openrouteservice\.org}).to_return(
      status: 200,
      body: {
        features: [{
          properties: { summary: { distance: 286.0, duration: 240.0 } },
          geometry: { type: "LineString", coordinates: [[2.3814, 48.8642]] }
        }]
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    sign_in @user
  end

  test "answers with the three durations the confirmation screen shows" do
    post go_meal_match_itinerary_path(@match),
         params: { start_latitude: 48.8642, start_longitude: 2.3814 }

    body = JSON.parse(response.body)

    # 2. Four minutes there, thirty at the table, four back
    assert_equal "4 min", body["travel_time"]
    assert_equal "30 min", body["meal_time"]
    assert_equal "38 min", body["total_time"]
  end

  test "still answers where to go next" do
    post go_meal_match_itinerary_path(@match),
         params: { start_latitude: 48.8642, start_longitude: 2.3814 }

    assert_equal go_meal_match_itinerary_path(@match),
                 JSON.parse(response.body)["redirect_to"]
  end
end
