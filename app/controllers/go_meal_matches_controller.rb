class GoMealMatchesController < ApplicationController
  def index
    @user = current_user
    @go_meal_matches = current_user.go_meal_matches.includes(:restaurant)
  end

  def like
    match = current_user.go_meal_matches.find(params[:id])
    match.update!(status: :liked)
    # redirect_to root_path
    head :ok
  end

  def reject
    match = current_user.go_meal_matches.find(params[:id])
    match.update!(status: :rejected)
    head :ok
  end
end
