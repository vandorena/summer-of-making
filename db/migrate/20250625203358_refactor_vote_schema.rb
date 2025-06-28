class RefactorVoteSchema < ActiveRecord::Migration[8.0]
  # Remove redundant fields, and rename some cols because we can have ties now
  def up
    add_reference :votes, :project_1, foreign_key: { to_table: :projects }
    add_reference :votes, :project_2, foreign_key: { to_table: :projects }

    rename_column :votes, :winner_demo_opened, :project_1_demo_opened
    rename_column :votes, :winner_readme_opened, :project_1_readme_opened
    rename_column :votes, :winner_repo_opened, :project_1_repo_opened
    rename_column :votes, :loser_demo_opened, :project_2_demo_opened
    rename_column :votes, :loser_readme_opened, :project_2_readme_opened
    rename_column :votes, :loser_repo_opened, :project_2_repo_opened

    remove_column :votes, :vote_number, :integer
    remove_reference :votes, :winning_project, foreign_key: { to_table: :projects }
    remove_reference :votes, :loser, foreign_key: { to_table: :projects }
  end

  def down
    add_column :votes, :vote_number, :integer
    add_reference :votes, :winning_project, foreign_key: { to_table: :projects }
    add_reference :votes, :loser, foreign_key: { to_table: :projects }

    rename_column :votes, :project_1_demo_opened, :winner_demo_opened
    rename_column :votes, :project_1_readme_opened, :winner_readme_opened
    rename_column :votes, :project_1_repo_opened, :winner_repo_opened
    rename_column :votes, :project_2_demo_opened, :loser_demo_opened
    rename_column :votes, :project_2_readme_opened, :loser_readme_opened
    rename_column :votes, :project_2_repo_opened, :loser_repo_opened

    remove_reference :votes, :project_1, foreign_key: { to_table: :projects }
    remove_reference :votes, :project_2, foreign_key: { to_table: :projects }
  end
end
