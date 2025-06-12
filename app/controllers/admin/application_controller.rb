# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    include PublicActivity::StoreController

    before_action :authenticate_admin!

    helper_method :current_user

    layout "admin"

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end

    private

    def authenticate_admin!
      redirect_to "https://www.youtube.com/watch?v=dQw4w9WgXcQ" unless current_user&.is_admin?
    end
  end
end
