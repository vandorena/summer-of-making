class AddUniqueConstraintToFraudReports < ActiveRecord::Migration[8.0]
  def change
    add_index :fraud_reports, [ :user_id, :suspect_type, :suspect_id ], unique: true, name: 'index_fraud_reports_on_user_and_suspect'
  end
end
