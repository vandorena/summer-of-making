class PayoutsController < ApplicationController
  before_action :verify_fraud_token, only: [:balance]

  def index
    @payouts = current_user.payouts
  end

  def balance
    user = User.find_by(slack_id: params[:slack_id])

    render json: {
      balance: user.balance,
      payouts: user.payouts,
    }
  end

  private

  def verify_fraud_token
    unless params[:token] == Rails.application.credentials.fraud.token
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
