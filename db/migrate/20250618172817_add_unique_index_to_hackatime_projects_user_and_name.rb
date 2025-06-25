class AddUniqueIndexToHackatimeProjectsUserAndName < ActiveRecord::Migration[8.0]
  def change
    add_index :hackatime_projects, [ :user_id, :name ], unique: true
  end
end
