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

    @route = route_info(@match.restaurant)

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

  def route_info(restaurant)
    user_result = Geocoder.search(current_user.preferred_start_address).first
    user_coordinates = [user_result.longitude, user_result.latitude]

    restaurant_coordinates = [
      restaurant.longitude,
      restaurant.latitude
    ]

    OsrmService.new(
      user_coordinates,
      restaurant_coordinates
    ).call
  end

end
