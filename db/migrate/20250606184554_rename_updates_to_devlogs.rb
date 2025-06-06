class RenameUpdatesToDevlogs < ActiveRecord::Migration[8.0]
  def change
    rename_table :updates, :devlogs

    # Rename columns update_id to devlog_id
    rename_column :comments, :update_id, :devlog_id
    rename_column :timer_sessions, :update_id, :devlog_id
  end
end
