class LocationsController < ApplicationController
  skip_after_action :verify_authorized

  def show
  end

  def create
    session[:location] = {
      "latitude" => params[:latitude],
      "longitude" => params[:longitude]
    }

    render json: { redirect_to: edit_preferences_path }
  end
end
