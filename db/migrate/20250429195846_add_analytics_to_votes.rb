class AddAnalyticsToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :winner_demo_opened, :boolean, default: false
    add_column :votes, :winner_readme_opened, :boolean, default: false
    add_column :votes, :winner_repo_opened, :boolean, default: false
    add_column :votes, :loser_demo_opened, :boolean, default: false
    add_column :votes, :loser_readme_opened, :boolean, default: false
    add_column :votes, :loser_repo_opened, :boolean, default: false
  end
end
