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
  def like
    @match = current_user.go_meal_matches.find(params[:id])
    authorize @match
    @match.update!(status: :liked)

    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to go_meal_match_path(@match) }
    end
  end

  def reject
    @match = current_user.go_meal_matches.find(params[:id])
    authorize @match
    @match.update!(status: :rejected)

    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to go_meal_matches_path }
    end
  end
end
