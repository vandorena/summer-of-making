class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  def toggle
    @like = @likeable.likes.find_by(user: current_user)

    if @like
      @like.destroy
      @liked = false
    else
      @like = @likeable.likes.create(user: current_user)
      @liked = true
    end

    @likeable.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_likeable
    if params[:id]
      @likeable = Devlog.find(params[:id])
    else
      head :not_found
    end
  end
end
