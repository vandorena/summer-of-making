class AddHackatimeProjectKeysToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :hackatime_project_keys, :string, array: true, default: []
  end
end
