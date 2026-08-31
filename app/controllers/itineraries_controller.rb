class ItinerariesController < ApplicationController
  before_action :set_match
  # ApplicationController names :index in both Pundit callbacks, an action this
  # controller does not have — Rails 8.1 raises on that. We drop them and put
  # verify_authorized back without the :index reference, so the safety net stays.
  skip_after_action :verify_authorized, raise: false
  skip_after_action :verify_policy_scoped, raise: false
  after_action :verify_authorized, unless: :skip_pundit?

  def create
    # 1. Keep the position in the session, not in the database: it is only
    #    useful for the length of this trip, and it is personal data
    session[:start_point] = {
      "match_id" => @match.id,
      "latitude" => params[:start_latitude],
      "longitude" => params[:start_longitude]
    }

    # 2. Answer where to go next, and the three durations the confirmation
    #    screen shows while the user is still deciding
    render json: { redirect_to: go_meal_match_itinerary_path(@match) }
    .merge(durations)
  end

  def show
    # 3. Read the position back
    @start_point = session[:start_point]

    # 4. Nothing to draw without it, and nothing to draw with another
    #    match's position either
    if @start_point.present? && @start_point["match_id"] == @match.id
      @route = walking_route
      return
    end

    redirect_to go_meal_match_path(@match),
                alert: "We need your position to show you the way."
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
    point = @start_point || session[:start_point]
    start_point = [point["longitude"].to_f, point["latitude"].to_f]
    finish_point = [@match.restaurant.longitude, @match.restaurant.latitude]

    WalkingRoute.new(start_point, finish_point).call
  end

  # The three tiles of the confirmation screen. Any of them may be nil —
  # no route, or a user who never set their lunch length. The screen keeps
  # showing a dash rather than a wrong number.
  def durations
    route = walking_route
    meal = current_user.average_lunch_time_minutes
    return {} if route.nil?

    {
      travel_time: helpers.walking_time(route[:duration]),
      meal_time: meal && helpers.meal_time(meal),
      total_time: meal && helpers.total_time(route[:duration], meal)
    }
  end
end
