class StaticPagesController < ApplicationController
  def gork
    redirect_to root_path, alert: "come back when you're a little....richer." unless current_user&.verified_check?
  end
end
