class PayoutsController < ApplicationController
  def index
    @payouts = current_user.payouts
  end

  def balance
    user = User.find(params[:slack_id])

    respond_to do |format|
      format.all do
        render json: {
          slack_id: user.slack_id,
          balance: user.balance
        }.to_json
      end
    end
  end
end
