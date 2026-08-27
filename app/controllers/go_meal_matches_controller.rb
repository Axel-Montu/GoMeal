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
  end

  # def create
  #   Restaurant.all.each do |restaurant|
  #     score = rand(0..100)
  #     @match = GoMealMatch.new(go_meal_score: score)
  #     @match.user = current_user
  #     @match.restaurant = restaurant
  #     @match.save
  #   end
  #   redirect_to go_meal_matches_path
  # end

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
