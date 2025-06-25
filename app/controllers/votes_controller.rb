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

    # Handle ties – Not implemented on the frontend yet
    if @vote.winning_project_id.blank?
      @vote.winning_project_id = nil
    end

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
    voted_project_ids = current_user.votes
                                   .joins(:vote_changes)
                                   .distinct
                                   .pluck("vote_changes.project_id")
    shipped_project_ids = Project
                           .joins(:ship_events)
                           .where.not(id: voted_project_ids)
                           .where.not(user_id: current_user.id)
                           .distinct
                           .pluck(:id)

    if shipped_project_ids.size < 2
      @projects = []
      return
    end

    # select 2 random projects
    selected_ids = shipped_project_ids.sample(2)
    @projects = Project.where(id: selected_ids)
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           winner_demo_opened winner_readme_opened winner_repo_opened
                           loser_demo_opened loser_readme_opened loser_repo_opened
                           time_spent_voting_ms music_played])
  end
end
