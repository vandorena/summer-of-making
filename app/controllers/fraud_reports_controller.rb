# frozen_string_literal: true

class FraudReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    FraudReport.create!(
      reporter: current_user,
      **fraud_report_params
    )

    flash[:notice] = "Thank you for reporting this. We'll investigate."
    redirect_to request.referer || root_path
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
