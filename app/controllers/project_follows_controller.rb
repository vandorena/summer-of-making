class ProjectFollowsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_project

  def create
    @project_follow = current_user.project_follows.build(project: @project)

    if @project_follow.save
      respond_to do |format|
        format.html do
          redirect_to @project, notice: "You are now following this project!"
        end
        format.turbo_stream do
          flash.now[:notice] = "You are now following this project!"
          Rails.logger.info "Rendering turbo_stream"
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                  partial: "projects/follow_button",
                                  locals: { project: @project, following: true })
          ]
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to @project, alert: @project_follow.errors.full_messages.join(", ")
        end
        format.turbo_stream do
          flash.now[:alert] = @project_follow.errors.full_messages.join(", ")
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                  partial: "projects/follow_button",
                                  locals: { project: @project, following: false })
          ]
        end
      end
    end
  end

  def destroy
    @project_follow = current_user.project_follows.find_by(project: @project)

    if @project_follow.destroy
      redirect_to @project, notice: "You have unfollowed this project."
    else
      redirect_to @project, alert: @project_follow.errors.full_messages.join(", ")
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authenticate_user!
    redirect_to new_user_session_path unless user_signed_in?
  end
end
