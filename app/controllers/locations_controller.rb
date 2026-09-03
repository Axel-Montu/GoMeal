class LocationsController < ApplicationController
  skip_after_action :verify_authorized

  def show
  end

  def create
    session[:location] = {
      "latitude" => params[:latitude],
      "longitude" => params[:longitude]
    }

    render json: { redirect_to: edit_preferences_path }
  end

  def update
    session[:location] = {
      "latitude" => params[:latitude],
      "longitude" => params[:longitude]
    }
    match = current_user.go_meal_matches.find_by(id: params[:go_meal_match_id])
    return head :not_found if match.nil?

    start_point = [params[:longitude].to_f, params[:latitude].to_f]
    finish_point = [match.restaurant.longitude, match.restaurant.latitude]
    route = WalkingRoute.new(start_point, finish_point).call

    LocationChannel.broadcast_to(
      current_user,
      user_position: start_point,
      geometry: route&.dig(:geometry),
      distance: route&.dig(:distance),
      duration: route&.dig(:duration)
    )

    head :no_content
  end
end
