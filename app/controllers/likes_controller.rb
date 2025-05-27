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

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { liked: @liked, likes_count: @likeable.likes_count } }
    end
  end

  private

  def set_likeable
    if params[:update_id]
      @likeable = Update.find(params[:update_id])
    else
      head :not_found
    end
  end
end 