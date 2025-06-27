# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_projects, only: %i[new]
  before_action :check_identity_verification

  # before_action :redirect_to_locked, except: [ :locked ] # For the first week

  def new
    @vote = Vote.new
    @user_vote_count = current_user.votes.count
  end

  def create
    project_1_id = params[:vote][:project_1_id]&.to_i
    project_2_id = params[:vote][:project_2_id]&.to_i

    unless project_1_id && project_2_id
      redirect_to new_vote_path, alert: "Missing project information"
      return
    end

    @projects = Project.where(id: [project_1_id, project_2_id]).to_a
    
    if @projects.size != 2
      redirect_to new_vote_path, alert: "Invalid projects selected"
      return
    end

    @vote = current_user.votes.build(vote_params)

    @vote.project_1_id = project_1_id
    @vote.project_2_id = project_2_id

    # Handle tie case
    if @vote.winning_project_id.blank?
      @vote.winning_project_id = nil
    end

    # Validate that winning project is one of the two projects
    if @vote.winning_project_id.present?
      valid_project_ids = [project_1_id, project_2_id]
      unless valid_project_ids.include?(@vote.winning_project_id.to_i)
        redirect_to new_vote_path, alert: "Invalid project selection"
        return
      end
    end

    if @vote.save
      vote_result = if @vote.winning_project_id.nil?
                     "Tie vote submitted!"
      else
                     "Vote submitted!"
      end

      redirect_to new_vote_path, notice: vote_result
    else
      redirect_to new_vote_path, alert: @vote.errors.full_messages.join(", ")
    end
  end

  def locked
    @approve_projects_count = Project.joins(:ship_certifications)
                                     .where(ship_certifications: { judgement: :approved })
                                     .size
    @full_projects_count = Project.joins(:ship_certifications, :devlogs)
                                  .where(ship_certifications: { judgement: :approved })
                                  .group("projects.id")
                                  .having("SUM(COALESCE(devlogs.seconds_coded, 0)) > ?", 10 * 3600)
                                  .count
                                  .keys
                                  .size
  end

  private

  def redirect_to_locked
    redirect_to locked_votes_path
  end


  def check_identity_verification
    return if current_user&.identity_vault_id.present? && current_user.verification_status != :ineligible

    redirect_to campfire_path, alert: "Please verify your identity to access this page."
  end

  def set_projects
    # Get projects that haven't been voted on by current user
    voted_ship_event_ids = current_user.votes
                                      .joins(vote_changes: { project: :ship_events })
                                      .distinct
                                      .pluck("ship_events.id")

    projects_with_latest_ship = Project
                                  .joins(:ship_events)
                                  .joins(:ship_certifications)
                                  .includes(:user, :banner_attachment,
                                           devlogs: [ :user, :file_attachment ])
                                  .where(ship_certifications: { judgement: :approved })
                                  .where.not(user_id: current_user.id)
                                  .where(
                                    ship_events: {
                                      id: ShipEvent.select("MAX(ship_events.id)")
                                                  .where("ship_events.project_id = projects.id")
                                                  .group("ship_events.project_id")
                                                  .where.not(id: voted_ship_event_ids)
                                    }
                                  )
                                  .distinct

    if projects_with_latest_ship.count < 2
      @projects = []
      return
    end

    eligible_projects = projects_with_latest_ship.to_a

      projects_with_time = eligible_projects.map do |project|
        latest_ship_event = project.ship_events.order(:created_at).last

        ship_devlogs = latest_ship_event.devlogs_since_last
                                       .where("created_at < ?", latest_ship_event.created_at)
        total_time_seconds = ship_devlogs.sum(:last_hackatime_time)

      {
        project: project,
        total_time: total_time_seconds
      }
    end

    if projects_with_time.size < 2
      @projects = []
      return
    end

    selected_projects = []
    used_user_ids = Set.new
    max_attempts = 25 # infinite loop!

    attempts = 0
    while selected_projects.size < 2 && attempts < max_attempts
      attempts += 1

      # pick a raqndom project and get smth in it's range
      if selected_projects.empty?
        first_project_data = projects_with_time.select { |p| !used_user_ids.include?(p[:project].user_id) }.sample
        next unless first_project_data

        selected_projects << first_project_data[:project]
        used_user_ids << first_project_data[:project].user_id
        first_time = first_project_data[:total_time]

        # find projects within the constraints (set to 30%)
        min_time = first_time * 0.7
        max_time = first_time * 1.3

        compatible_projects = projects_with_time.select do |p|
          !used_user_ids.include?(p[:project].user_id) &&
          p[:total_time] >= min_time &&
          p[:total_time] <= max_time
        end

        if compatible_projects.any?
          second_project_data = compatible_projects.sample
          selected_projects << second_project_data[:project]
          used_user_ids << second_project_data[:project].user_id
        else
          selected_projects.clear
          used_user_ids.clear
        end
      end
    end

    if selected_projects.size < 2
      @projects = []
      return
    end

    @projects = selected_projects
    @ship_events = selected_projects.map do |project|
      project.ship_events.order(:created_at).last
    end
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           project_1_demo_opened project_1_readme_opened project_1_repo_opened
                           project_2_demo_opened project_2_readme_opened project_2_repo_opened
                           time_spent_voting_ms music_played project_1_id project_2_id])
  end
end