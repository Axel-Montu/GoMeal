class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  include Pundit::Authorization

  after_action :verify_authorized, unless: -> { skip_pundit? || action_name == "index" }
  after_action :verify_policy_scoped, if: -> { action_name == "index" && !skip_pundit? }

  private

  def skip_pundit?
    devise_controller? ||
      params[:controller] =~ /(^(rails_)?admin)|(^pages$)|(^components$)/
  end
end
