class AddResolvedToFraudReports < ActiveRecord::Migration[8.0]
  def change
    add_column :fraud_reports, :resolved, :boolean, default: false, null: false
  end
end
