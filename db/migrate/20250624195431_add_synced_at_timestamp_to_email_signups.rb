class AddSyncedAtTimestampToEmailSignups < ActiveRecord::Migration[8.0]
  def change
    add_column :email_signups, :synced_at, :datetime
  end
end
