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
      redirect_to locations_path, alert: "Nous avons besoin de ta localisation pour t'emmener au restaurant."
      return
    end

    @route = walking_route
    mark_expected_back
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

  def mark_expected_back
    # 1. Never push the return time back: the first "Y aller" is the one that
    #    counts
    return if @match.expected_back_at.present?
    # 2. No route means no reliable walking time
    return if @route.blank?

    # 3. Walking comes in seconds, lunch in minutes
    walking = @route[:duration].seconds
    lunch = current_user.average_lunch_time_minutes.to_i.minutes

    # 4. Record when the user should be back at their desk
    @match.update!(expected_back_at: Time.current + walking + lunch)
  end

  def walking_route
    # 5. Longitude first, both times — the order OpenRouteService expects
    point = session[:location]
    start_point = [point["longitude"].to_f, point["latitude"].to_f]
    finish_point = [@match.restaurant.longitude, @match.restaurant.latitude]

    WalkingRoute.new(start_point, finish_point).call
  end
end
