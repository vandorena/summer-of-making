module Admin
  class StaticPagesController < ApplicationController
    skip_before_action :authenticate_admin!, only: [ :index ]

    def index
      render html: "<h1>bruh</h1>".html_safe unless current_user&.is_admin
    end
  end
end
