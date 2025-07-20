# frozen_string_literal: true

class FraudReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    fraud_report = FraudReport.new(
      reporter: current_user,
      **fraud_report_params
    )

    unless valid_report(fraud_report)
      flash[:alert] = "nice try silly!"
      redirect_to request.referer || root_path
      return
    end

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

  def valid_report(fraud_report)
    reason = fraud_report.reason

    return false if reason.blank? || reason.length < 20
    return false if reason.length > 1000
    sr = ActionController::Base.helpers.strip_tags(reason)
    fraud_report.reason = sr.strip

    sussy = [
      /<script/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe/i,
      /<object/i,
      /<embed/i,
      /<form/i,
      /data:text\/html/i,
      /vbscript:/i,
      /<meta/i
    ]

    sussy.each do |pattern|
      return false if reason.match?(pattern)
    end

    sc = reason.scan(/[<>{}()\[\]"'`]/).length
    return false if sc > 10

    ac = reason.scan(/[a-zA-Z0-9\s]/).length
    return false if ac < (reason.length * 0.7)

    true
  end
end
