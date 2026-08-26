class PreferencesController < ApplicationController
  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user

    if @user.update(preferences_params)
      redirect_to root_path, notice: "Preferences updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def preferences_params
    params.require(:user).permit(
      :average_lunch_time_minutes,
      :preferred_start_address
    )
  end
end