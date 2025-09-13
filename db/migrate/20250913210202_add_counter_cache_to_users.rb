class AddCounterCacheToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add columns without defaults to avoid table locks
    add_column :users, :projects_count, :integer
    add_column :users, :devlogs_count, :integer
    add_column :users, :votes_count, :integer
    add_column :users, :ship_events_count, :integer
  end
end
