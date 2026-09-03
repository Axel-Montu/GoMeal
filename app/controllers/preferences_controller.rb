class PreferencesController < ApplicationController
  CUISINE_CATEGORIES = [
    "Régime particulier",
    "Cuisines du monde",
    "Spécialité"
  ].freeze

  CUISINE_WORLD_CATEGORY = "Cuisines du monde"
  CUISINE_SPECIALTY_CATEGORY = "Spécialité"
  PINNED_TAGS_COUNT = 7

  def show
    @user = current_user
    authorize @user, :edit?
  end

  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user
    if @user.update(preferences_params)
      redirect_to cuisines_preferences_path, notice: "Preferences updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def cuisines
    @user = current_user
    authorize @user, :edit?
    @tags_by_category = tags_by_category
    @submenu_groups_by_category = submenu_groups_by_category(@tags_by_category)
  end

  def update_cuisines
    @user = current_user
    authorize @user, :edit?

    unless @user.update(cuisines_params)
      @tags_by_category = tags_by_category
      @submenu_groups_by_category = submenu_groups_by_category(@tags_by_category)
      return render(:cuisines, status: :unprocessable_entity)
    end

    location = session[:location]
    if location.blank?
      redirect_to locations_path, alert: "Nous avons besoin de votre position." and return
    end

    generate_matches_or_render_error(location)
  end

  # Same responsibility as the tail of #update_cuisines, but for the retry CTA
  # after an API failure: cuisines are already saved in DB, we only need to
  # rerun the nearby search + scoring.
  def retry_matches
    @user = current_user
    authorize @user, :edit?

    location = session[:location]
    if location.blank?
      redirect_to locations_path, alert: "Nous avons besoin de votre position." and return
    end

    generate_matches_or_render_error(location)
  end

  private

  def generate_matches_or_render_error(location)
    restaurants = Restaurants::NearbySearch.call(
      user: @user,
      latitude: location["latitude"],
      longitude: location["longitude"]
    )

    # nil means the Places API failed — keep existing matches intact and
    # show the full-screen retry view instead of wiping the user's data.
    if restaurants.nil?
      return render "preferences/api_error", status: :bad_gateway
    end

    @user.go_meal_matches.destroy_all
    restaurants.each do |restaurant|
      score = Scoring::GoMealScorer.call(restaurant: restaurant, user_location: location, user: @user)
      @user.go_meal_matches.create!(restaurant: restaurant, go_meal_score: score)
    end

    redirect_to go_meal_matches_path, notice: "Préférences culinaires mises à jour."
  end

  def preferences_params
    params.require(:user).permit(
      :average_lunch_time_minutes,
      :preferred_start_address,
      :max_walking_minutes,
      :budget
    )
  end

  def cuisines_params
    params.require(:user).permit(tag_ids: [])
  end

  def tags_by_category
    Tag.where(frontend_tag: CUISINE_CATEGORIES).order(:frontend_type).group_by(&:frontend_tag)
  end

  # Splits each branch's tags into a short always-visible "pinned" set and
  # the rest grouped by their submenu (region for cuisines, dish family for
  # specialties) so each group can fold behind its own <details>.
  def submenu_groups_by_category(tags_by_category)
    {
      CUISINE_WORLD_CATEGORY => submenu_groups(tags_by_category[CUISINE_WORLD_CATEGORY]),
      CUISINE_SPECIALTY_CATEGORY => submenu_groups(tags_by_category[CUISINE_SPECIALTY_CATEGORY])
    }
  end

  def submenu_groups(tags)
    tags = Array(tags)
    pinned = tags.sample(PINNED_TAGS_COUNT)
    remaining = tags - pinned

    groups = remaining.group_by(&:submenu).sort.to_h
    groups.transform_values! { |group_tags| group_tags.sort_by(&:display_name) }

    { pinned: pinned, groups: groups }
  end
end
