class AddHackatimeProjectsKeySnapshotToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :hackatime_projects_key_snapshot, :jsonb, default: [], null: false
  end
end
