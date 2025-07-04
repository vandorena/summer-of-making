# frozen_string_literal: true

class FraudReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    FraudReport.create!(
      reporter: current_user,
      **fraud_report_params
    )

    respond_to do |format|
      format.html { redirect_to request.referer || root_path, notice: "Thank you for reporting this. We'll investigate." }
      format.json { render json: { status: "success", message: "Thank you for reporting this. We'll investigate." } }
      format.turbo_stream { flash.now[:notice] = "Thank you for reporting this. We'll investigate." }
    end
  rescue => e
    Rails.logger.error "Fraud report creation failed: #{e.message}"
    Honeybadger.notify(e)
    respond_to do |format|
      format.html { redirect_to request.referer || root_path, alert: "Unable to submit report. Please try again." }
      format.json { render json: { status: "error", message: "Unable to submit report. Please try again." }, status: :unprocessable_entity }
      format.turbo_stream { flash.now[:alert] = "Unable to submit report. Please try again." }
    end
  end

  private

  def fraud_report_params
    params.require(:fraud_report).permit(:suspect_type, :suspect_id)
  end
end
