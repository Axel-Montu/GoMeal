class PreferencesController < ApplicationController
  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user
    GoMealMatch.destroy_all
    if @user.update(preferences_params)
      Restaurant.all.each do |restaurant|
        score = rand(0..100)
        @match = GoMealMatch.new(go_meal_score: score)
        @match.user = current_user
        @match.restaurant = restaurant
        @match.save
      end
      redirect_to go_meal_matches_path, notice: "Preferences updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def preferences_params
    params.require(:user).permit(
      :average_lunch_time_minutes,
      :preferred_start_address,
      :max_walking_minutes
    )
  end
end
