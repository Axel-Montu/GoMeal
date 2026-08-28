require "net/http"
require "json"

# Talks to OpenRouteService and nothing else: it knows how to ask for a walking
# route, not when to ask or what to do with it.
#
# Adapted from @DavidDDS1978's OsrmService (PR #60). Two changes: the geojson
# format, because the itinerary screen needs the geometry and not only the
# figures, and the name — this is OpenRouteService, not OSRM.
class WalkingRoute
  ENDPOINT = "https://api.openrouteservice.org/v2/directions/foot-walking/geojson".freeze

  # Both points are [longitude, latitude] — the order ORS expects, and the
  # reverse of what navigator.geolocation hands the browser.
  def initialize(start_point, finish_point)
    @start_point = start_point
    @finish_point = finish_point
  end

  def call
    # 1. A missing key is a setup problem, not a missing route: it must fail
    #    loudly, and outside the rescue below
    response = post_to_openrouteservice(ENV.fetch("ORS_API_KEY"))
    return nil unless response.is_a?(Net::HTTPSuccess)

    # 2. No feature means no walking route between these two points
    feature = JSON.parse(response.body).dig("features", 0)
    return nil if feature.nil?

    route_from(feature)
  rescue JSON::ParserError, NoMethodError
    # 3. A malformed answer is a missing route, not a crash
    nil
  end

  private

  # Keeps the three fields the screen needs, drops the rest
  def route_from(feature)
    summary = feature.dig("properties", "summary")

    {
      distance: summary["distance"],
      duration: summary["duration"],
      geometry: feature["geometry"]
    }
  end

  def post_to_openrouteservice(api_key)
    uri = URI(ENDPOINT)

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = api_key
    request["Content-Type"] = "application/json"
    request.body = { coordinates: [@start_point, @finish_point] }.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  rescue StandardError
    # 5. Timeout, DNS failure, connection refused — all end the same way
    nil
  end
end
