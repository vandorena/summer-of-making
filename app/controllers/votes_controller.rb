# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_projects, only: %i[new create]
  before_action :check_identity_verification

  # before_action :redirect_to_locked, except: [ :locked ] # For the first week

  def new
    @vote = Vote.new
    @user_vote_count = current_user.votes.count

    session[:vote_tokens] = {}

    # Don't really care for now
    @projects.each do |project|
      token = SecureRandom.hex(16)
      session[:vote_tokens][token] = {
        "user_id" => current_user.id,
        "project_1_id" => @projects[0].id,
        "project_2_id" => @projects[1].id,
        "expires_at" => 2.hours.from_now.iso8601
      }
    end
    Rails.logger.info("Vote tokens: #{session[:vote_tokens]}")
  end

  def create
    token = params[:vote_token]
    token_data = session[:vote_tokens]

    @vote = current_user.votes.build(vote_params)

    @vote.project_1_id = @projects[0].id
    @vote.project_2_id = @projects[1].id

    # unless @vote.authorized_with_token?(token_data)
    #   redirect_to new_vote_path, alert: "Vote validation failed"
    #   return
    # end

    if @vote.save
      session[:vote_tokens].delete(token)

      redirect_to new_vote_path, notice: "Vote Submitted!"
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
    # This needs to be re-written, please ignore for now!
    voted_ship_event_ids = current_user.votes
                                      .joins(vote_changes: { project: :ship_events })
                                      .distinct
                                      .pluck("ship_events.id")

    @projects = [Project.find(1), Project.find(4)]
                                  # .joins(:ship_events)
                                  # .joins(:ship_certifications)
                                  # .where(ship_certifications: { judgement: :approved })
                                  # # .where.not(user_id: current_user.id)
                                  # .where(                              # we' are getting the max ship event id for each project which should ensure it's the latest ship event
                                  #   ship_events: {
                                  #     id: ShipEvent.select("MAX(ship_events.id)")
                                  #                 .where("ship_events.project_id = projects.id")
                                  #                 .group("ship_events.project_id")
                                  #                 .where.not(id: voted_ship_event_ids)
                                  #   }
                                  # )
                                  # .distinct

    # if projects_with_latest_ship.count < 2
    #   @projects = []
    #   return
    # end

    # eligible_projects = projects_with_latest_ship.to_a

    # # two projects by different authors
    # selected_projects = []
    # used_user_ids = Set.new

    # eligible_projects.shuffle!

    # eligible_projects.each do |project|
    #   next if used_user_ids.include?(project.user_id)

    #   selected_projects << project
    #   used_user_ids << project.user_id

    #   break if selected_projects.size == 2
    # end

    # if selected_projects.size < 2
    #   @projects = []
    #   return
    # end

    # @projects = selected_projects
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           project_1_demo_opened project_1_readme_opened project_1_repo_opened
                           project_2_demo_opened project_2_readme_opened project_2_repo_opened
                           time_spent_voting_ms music_played])
  end
end
