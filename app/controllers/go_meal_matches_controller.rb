class GoMealMatchesController < ApplicationController
  def index
    @user = current_user
    @go_meal_matches = current_user.go_meal_matches.includes(:restaurant).order(go_meal_score: :desc)
    policy_scope(@go_meal_matches)
  end

  def show
    # 1. Look among the current user's own matches only: someone else's is
    #    simply not found
    @match = current_user.go_meal_matches.find_by(id: params[:id])

    if @match.nil?
      # 2. A 404, and we never say whether the match exists elsewhere
      skip_authorization
      head :not_found
      return
    end

    authorize @match
    @back_path = go_meal_matches_path

    # 3. The review, when one was already written
    @review = @match.review

    @route = walking_route
    @meal = current_user.average_lunch_time_minutes
    # 4. The last known user position, so the review prompt can trigger on
    #    arrival at the restaurant even before the clock catches up
    @current_location = session[:location]
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

  def not_visited
    # 1. Look among the current user's own matches only
    @match = current_user.go_meal_matches.find_by(id: params[:id])

    if @match.nil?
    # 2. A 404, and we never say whether the match exists elsewhere
    skip_authorization
    head :not_found
    return
  end

  authorize @match

  # 3. The answer is recorded: this lunch leaves the waiting list for good
  @match.update!(visited: false)

  # 4. Back to the matches, with a word saying it was taken into account
  redirect_to go_meal_matches_path, notice: "C'est noté, tu n'y es pas allé."
  end

  # Fermeture temporaire du prompt de notation, sans réponse. On stocke l'id
  # du match en session pour que le bottom sheet ne réapparaisse pas tant que
  # la session dure. Les vraies réponses (noter / pas allé) restent le seul
  # moyen de faire sortir le match de la liste d'attente pour de bon.
  def dismiss_rate_prompt
    @match = current_user.go_meal_matches.find_by(id: params[:id])

    if @match.nil?
      skip_authorization
      head :not_found
      return
    end

    authorize @match

    session[:dismissed_rate_prompts] ||= []
    session[:dismissed_rate_prompts] |= [@match.id]

    head :no_content
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
