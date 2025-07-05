# frozen_string_literal: true

class ViewTrackingController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]
  before_action :authenticate_request

  def create
    viewable_type = params[:viewable_type]
    viewable_id = params[:viewable_id]

    unless viewable_type.in?(%w[Project Devlog]) && viewable_id.present?
      render json: { error: "wuh" }, status: :bad_request
      return
    end

    viewable = viewable_type.constantize.find_by(id: viewable_id)
    unless viewable
      render json: { error: "#{viewable_type} not found" }, status: :not_found
      return
    end

    ViewTrackingService.track_view(
      viewable,
      user_id: current_user&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: { success: true }
  end

  private

  def authenticate_request
    true
  end
end
