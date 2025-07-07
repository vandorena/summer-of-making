class Admin::FraudReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @total_reports = FraudReport.count
    @unique_projects = FraudReport.where(suspect_type: "Project").select(:suspect_id).distinct.count
    @recent_reports = FraudReport.where("created_at >= ?", 24.hours.ago).count
    @fraud_reports = FraudReport.order(created_at: :desc).includes(:reporter, :suspect).limit(100)
  end

  private
  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "lmao"
    end
  end
end
