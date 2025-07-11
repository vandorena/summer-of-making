class PayoutsController < ApplicationController
  before_action :verify_fraud_token, if: -> { request.format.json? }

  def index
    respond_to do |format|
      format.json do
        user = User.find_by(slack_id: params[:slack_id])

        return render json: { error: "User not found" }, status: :not_found unless user

        if current_user != user && !current_user&.is_admin?
          return render json: { error: "wuh" }, status: :forbidden
        end

        render json: {
          balance: user.balance,
          payouts: user.payouts
        }
      end
      format.html { @payouts = current_user.payouts }
    end
  end

  private

  def verify_fraud_token
    unless params[:token] == Rails.application.credentials.fraud.token
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
