class GoMealMatchesController < ApplicationController
  def index
    @user = current_user
    @go_meal_matches = current_user.go_meal_matches.includes(:restaurant)
    policy_scope(@go_meal_matches)
  end

# route[:distance_meters]
# route[:duration_minutes]

  def show
    @match = GoMealMatch.find(params[:id])
    authorize @match
    @back_path = go_meal_matches_path
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
end
