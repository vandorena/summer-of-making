class BackfillCounterCaches < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Projects counter caches
    Project.in_batches(of: 1000) do |batch|
      batch.update_all(
        "ship_events_count = (SELECT COUNT(*) FROM ship_events WHERE ship_events.project_id = projects.id),
         followers_count = (SELECT COUNT(*) FROM project_follows WHERE project_follows.project_id = projects.id),
         devlogs_count = (SELECT COUNT(*) FROM devlogs WHERE devlogs.project_id = projects.id)"
      )
    end

    # Users counter caches
    User.in_batches(of: 1000) do |batch|
      batch.update_all(
        "projects_count = (SELECT COUNT(*) FROM projects WHERE projects.user_id = users.id AND projects.is_deleted = false),
         devlogs_count = (SELECT COUNT(*) FROM devlogs WHERE devlogs.user_id = users.id),
         votes_count = (SELECT COUNT(*) FROM votes WHERE votes.user_id = users.id),
         ship_events_count = (SELECT COUNT(*) FROM ship_events INNER JOIN projects ON ship_events.project_id = projects.id WHERE projects.user_id = users.id AND projects.is_deleted = false)"
      )
    end

    # Set default values first, then NOT NULL constraints
    change_column_default :projects, :ship_events_count, from: nil, to: 0
    change_column_default :projects, :followers_count, from: nil, to: 0
    change_column_default :users, :projects_count, from: nil, to: 0
    change_column_default :users, :devlogs_count, from: nil, to: 0
    change_column_default :users, :votes_count, from: nil, to: 0
    change_column_default :users, :ship_events_count, from: nil, to: 0

    # Safe to add NOT NULL since we backfilled and set defaults
    safety_assured do
      change_column_null :projects, :ship_events_count, false
      change_column_null :projects, :followers_count, false
      change_column_null :users, :projects_count, false
      change_column_null :users, :devlogs_count, false
      change_column_null :users, :votes_count, false
      change_column_null :users, :ship_events_count, false
    end
  end

  def down
  end
end
