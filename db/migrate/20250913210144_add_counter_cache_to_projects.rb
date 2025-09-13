class AddCounterCacheToProjects < ActiveRecord::Migration[8.0]
  def change
    # Add columns without defaults to avoid table locks
    add_column :projects, :ship_events_count, :integer
    add_column :projects, :followers_count, :integer
  end
end
