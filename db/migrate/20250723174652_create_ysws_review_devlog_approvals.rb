class CreateYswsReviewDevlogApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :ysws_review_devlog_approvals do |t|
      t.references :devlog, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true, comment: "The reviewer who made this approval"
      t.boolean :approved, null: false
      t.integer :approved_seconds, comment: "Seconds approved by reviewer (may differ from devlog.duration_seconds)"
      t.text :notes, comment: "Internal notes from the reviewer"
      t.datetime :reviewed_at, null: false

      t.timestamps
    end
  end
end
