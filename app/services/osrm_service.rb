require "net/http"
require "json"

class OsrmService
  def initialize(user_coordinates, restaurant_coordinates)
    @user_coordinates = user_coordinates
    @restaurant_coordinates = restaurant_coordinates
  end

  def call

    uri = URI("https://api.heigit.org/openrouteservice/v2/directions/foot-walking/json")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = ENV["OPENROUTESERVICE_API_KEY"]
    request["Content-Type"] = "application/json"

    request.body = {
      coordinates: [
        @user_coordinates,
        @restaurant_coordinates
      ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)

    summary = data["routes"][0]["summary"]

    {
      distance_meters: summary["distance"].round,
      duration_minutes: (summary["duration"] / 60.0).round
    }
  end
end