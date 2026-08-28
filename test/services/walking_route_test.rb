require "test_helper"

class WalkingRouteTest < ActiveSupport::TestCase
  # 1. Two points in the 11th, longitude first — the order ORS expects
  START = [ 2.3814, 48.8642 ].freeze
  FINISH = [ 2.3806, 48.8530 ].freeze

  ENDPOINT = "https://api.openrouteservice.org/v2/directions/foot-walking/geojson".freeze

  test "returns the distance, the duration and the geometry" do
    # 2. Answer with the shape ORS really sends back
    stub_request(:post, ENDPOINT).to_return(
      status: 200,
      body: {
        features: [ {
          properties: { summary: { distance: 842.3, duration: 611.7 } },
          geometry: { type: "LineString", coordinates: [ START, FINISH ] }
        } ]
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    route = WalkingRoute.new(START, FINISH).call

    assert_in_delta 842.3, route[:distance], 0.1
    assert_in_delta 611.7, route[:duration], 0.1
    assert_equal "LineString", route[:geometry]["type"]
  end

  test "returns nil when there is no walking route between the points" do
    # 3. ORS answers 404 with an error payload when the points are unreachable
    stub_request(:post, ENDPOINT).to_return(status: 404, body: "{}")

    assert_nil WalkingRoute.new(START, FINISH).call
  end

  test "returns nil when the network fails" do
    # 4. A timeout must never reach the user as a 500
    stub_request(:post, ENDPOINT).to_timeout

    assert_nil WalkingRoute.new(START, FINISH).call
  end
end
