class RemoveHasHackatimeProjectsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :has_hackatime_projects
  end
end
