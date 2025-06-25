class AddSyncedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :synced_at, :timestamp
  end
end
