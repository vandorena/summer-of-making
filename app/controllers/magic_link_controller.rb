class MagicLinkController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_magic_token_service_agent

  def get_secret_magic_url
    slack_id = params.require(:slack_id)
    email = params.require(:email)

    return if EmailSignup.where(email:).empty?

    begin
      user = User.create_from_slack slack_id

      Rails.logger.tagged("MagicLink") do
        Rails.logger.info({
          event: "created_user",
          id: user.id,
          slack_id: user.slack_id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name
        }.to_json)
      end
    rescue StandardError => e
      user = User.find_by(email:)
    end

    link = MagicLink.find_or_create_by(user:).secret_url request.host

    respond_to do |format|
      format.all { render json: { success: true, link: } }
    end
  end

  private

  def authenticate_magic_token_service_agent
    unless params.require(:token) == Rails.application.credentials.explorpheus.token
      render json: { success: false, error: "Unauthorized" }, status: :unauthorized
      return
    end
  end
end
