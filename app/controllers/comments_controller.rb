# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_devlog

  def create
    authorize Comment
    @comment = @devlog.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      current_user.update(has_commented: true) unless current_user.has_commented
      redirect_to @devlog.project, notice: "Comment was successfully created."
    else
      redirect_to @devlog.project, alert: "Failed to add comment."
    end
  end

  def destroy
    @comment = @devlog.comments.find(params[:id])
    authorize @comment
    unless @comment.user == current_user || current_user.is_admin?
      redirect_to @devlog.project, alert: "You can only delete your own comments."
      return
    end

    if @comment.destroy
      redirect_to @devlog.project, notice: "Comment deleted successfully!"
    else
      redirect_to @devlog.project, alert: "Failed to delete comment."
    end
  end

  private

  def set_devlog
    @devlog = Devlog.find(params[:devlog_id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
