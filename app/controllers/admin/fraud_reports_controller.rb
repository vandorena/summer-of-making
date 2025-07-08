module Admin
  class FraudReportsController < ApplicationController
    def index
      @total_reports = FraudReport.count
      @unique_projects = FraudReport.where(suspect_type: "Project").select(:suspect_id).distinct.count
      @recent_reports = FraudReport.where("created_at >= ?", 24.hours.ago).count
      @fraud_reports = FraudReport.order(created_at: :desc).includes(:reporter, :suspect).limit(100)
    end
  end
end
