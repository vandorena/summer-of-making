# frozen_string_literal: true

class DevlogsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_project, only: %i[create destroy update]
  before_action :set_devlog, only: %i[destroy update]
  before_action :check_if_shipped, only: %i[create destroy update]
  skip_before_action :authenticate_user!, only: [ :api_create ]
  before_action :authenticate_api_key, only: [ :api_create ]
  skip_before_action :verify_authenticity_token, only: [ :api_create ]
  def index
    @page = [ params[:page].to_i, 1 ].max
    @per_page = 10

    @devlogs = Devlog.includes(:project, :user)
                     .where(project_id: current_user.followed_projects.pluck(:id))
                     .order(created_at: :desc)
                     .offset((@page - 1) * @per_page)
                     .limit(@per_page)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @project = Project.find(params[:project_id])

    if @project.hackatime_keys.present? && current_user.has_hackatime? && params[:devlog][:timer_session_id].blank?
      current_user.refresh_hackatime_data_now
    end

    # Skip time verification if user is linking a timer session
    if params[:devlog][:timer_session_id].blank? &&
       @project.hackatime_keys.present? && current_user.has_hackatime? &&
       current_user.hackatime_stat.present? &&
       !current_user.hackatime_stat.has_enough_time_since_last_update?(@project)
      seconds_needed = current_user.hackatime_stat.seconds_needed_since_last_update(@project)
      redirect_to project_path(@project),
                  alert: "You need to spend more time on this project before posting a devlog. #{helpers.format_seconds(seconds_needed)} more needed since your last update."
      return
    end

    if ENV["UPDATES_STATUS"] == "locked"
      redirect_to @project,
                  alert: "Posting devlogs is currently locked. Please check back later when devlogs are unlocked."
      return
    end

    @devlog = @project.devlogs.build(devlog_params)
    @devlog.user = current_user

    if @project.hackatime_keys.present? && @project.user.has_hackatime? && params[:devlog][:timer_session_id].blank?
      @devlog.last_hackatime_time = @project.user.hackatime_stat.time_since_last_update_for_project(@project)
    end

    if @devlog.save
      redirect_to @devlog.project, notice: "Devlog was successfully posted."
    else
      redirect_to @devlog.project, alert: "Failed to post devlog."
    end
  end

  def update
    if @devlog.user != current_user
      flash.now[:alert] = "You can only edit your own devlogs."
      redirect_to @devlog.project, alert: "You can only edit your own devlogs."
      return
    end

    # Only allow editing the text field
    if @devlog.update(devlog_params.slice(:text))
      redirect_to @devlog.project, notice: "Devlog was successfully edited."
    else
      redirect_to @devlog.project, alert: "Failed to edit devlog."
    end
  end

  def destroy
    if @devlog.user == current_user
      @devlog.destroy
      redirect_to @devlog.project, notice: "Devlog was successfully deleted."
    else
      redirect_to @devlog.project, alert: "You can only delete your own devlogs."
    end
  end

  def api_create
    if ENV["UPDATES_STATUS"] == "locked"
      return render json: { error: "Posting devlogs is currently locked" }, status: :forbidden
    end

    user = User.find_by(slack_id: params[:slack_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    project = Project.find_by(id: params[:project_id])
    return render json: { error: "Project not found" }, status: :not_found unless project

    devlog = project.devlogs.build(devlog_params)
    devlog.user = user

    if devlog.save
      render json: { message: "Devlog successfully created", devlog: devlog }, status: :created
    else
      render json: { error: "Failed to create devlog", details: devlog.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_devlog
    @devlog = @project.devlogs.find(params[:id])
  end

  def check_if_shipped
    return unless @project.is_shipped?

    redirect_to @project, alert: "This project has been shipped and cannot be modified."
  end

  def authenticate_api_key
    api_key = request.headers["Authorization"]
    return if api_key.present? && api_key == ENV["API_KEY"]

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def devlog_params
    params.expect(devlog: %i[text attachment timer_session_id])
  end
end
