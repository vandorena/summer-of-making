module Admin
  class ApplicationController < ActionController::Base
    before_action :authenticate_admin!

    helper_method :current_user

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    private

    def authenticate_admin!
      redirect_to "https://www.youtube.com/watch?v=dQw4w9WgXcQ" unless current_user&.is_admin?
    end
  end
end