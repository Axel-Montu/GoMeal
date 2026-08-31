class GoMealMatchesController < ApplicationController
  def index
    @user = current_user
    @go_meal_matches = current_user.go_meal_matches.includes(:restaurant)
    policy_scope(@go_meal_matches)
  end

  def show
    @match = GoMealMatch.find(params[:id])
    authorize @match
    @back_path = go_meal_matches_path

    @route = walking_route
    @meal = current_user.average_lunch_time_minutes
  end
  def like
    @match = current_user.go_meal_matches.find(params[:id])

    # redirect_to root_path
    authorize @match
  end

  def reject
    @match = current_user.go_meal_matches.find(params[:id])
    @match.update!(status: :rejected)

    authorize @match
  end

  private

  def walking_route
    point = session[:location]
    return nil if point.blank?

    # Longitude first, both times — the order OpenRouteService expects
    start_point = [point["longitude"].to_f, point["latitude"].to_f]
    finish_point = [@match.restaurant.longitude, @match.restaurant.latitude]

    WalkingRoute.new(start_point, finish_point).call
  end
end
