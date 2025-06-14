class AddUsedAiToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :used_ai, :boolean
  end
end
