class ItinerariesController < ApplicationController
  before_action :set_match
  # ApplicationController names :index in both Pundit callbacks, an action this
  # controller does not have — Rails 8.1 raises on that. We drop them and put
  # verify_authorized back without the :index reference, so the safety net stays.
  skip_after_action :verify_authorized, raise: false
  skip_after_action :verify_policy_scoped, raise: false
  after_action :verify_authorized, unless: :skip_pundit?

  def show
    # 1. The position was already captured on the /locations gate page
    if session[:location].blank?
      redirect_to locations_path, alert: "We need your position to show you the way."
      return
    end

    @route = walking_route
  end

  private

  def set_match
    # 5. Look among the current user's own matches only: someone else's
    #    is simply not found
    @match = current_user.go_meal_matches.find_by(id: params[:go_meal_match_id])

    if @match.nil?
      # 6. A 404, and we never say whether the match exists elsewhere
      skip_authorization
      head :not_found
    else
      authorize @match, policy_class: ItineraryPolicy
    end
  end

  def walking_route
    # 5. Longitude first, both times — the order OpenRouteService expects
    point = session[:location]
    start_point = [point["longitude"].to_f, point["latitude"].to_f]
    finish_point = [@match.restaurant.longitude, @match.restaurant.latitude]

    WalkingRoute.new(start_point, finish_point).call
  end
end
