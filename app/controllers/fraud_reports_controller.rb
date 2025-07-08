# frozen_string_literal: true

class FraudReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    fraud_report = FraudReport.new(
      reporter: current_user,
      **fraud_report_params
    )

    if fraud_report.save
      flash[:notice] = "Thank you for reporting this. We'll investigate."
      redirect_to request.referer || root_path
    else
      if fraud_report.errors[:user_id].any?
        flash[:alert] = "You have already reported this project."
      else
        flash[:alert] = "Unable to submit report. Please try again."
      end
      redirect_to request.referer || root_path
    end
  rescue => e
    Rails.logger.error "Fraud report creation failed: #{e.message}"
    Honeybadger.notify(e)
    flash[:alert] = "Unable to submit report. Please try again."
    redirect_to request.referer || root_path
  end

  private

  def fraud_report_params
    params.require(:fraud_report).permit(:suspect_type, :suspect_id, :reason)
  end
end
