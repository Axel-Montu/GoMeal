class OsrmService
  def initialize(user_coordinates, restaurant_coordinates)
    @user_coordinates = user_coordinates
    @restaurant_coordinates = restaurant_coordinates
  end

  def call
    url = "https://router.project-osrm.org/route/v1/driving/#{@user_coordinates.join(',')};#{@restaurant_coordinates.join(',')}?overview=false"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    {
      distance_meters: data["routes"][0]["distance"],
      distance_km: (data["routes"][0]["distance"] / 1000.0).round(1),
      duration_seconds: data["routes"][0]["duration"],
      duration_minutes: (data["routes"][0]["duration"] / 60.0).round
    }
  end
end