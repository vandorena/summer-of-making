class CreateFraudReports < ActiveRecord::Migration[8.0]
  def change
    create_table :fraud_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :suspect_type
      t.bigint :suspect_id
      t.string :reason

      t.timestamps
    end
  end
end
