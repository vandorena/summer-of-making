class RemoveProjectReadmeOpenedFromVote < ActiveRecord::Migration[8.0]
  def change
    remove_column :votes, :project_1_readme_opened
    remove_column :votes, :project_2_readme_opened
  end
end
