class AddWinnerAndLoserIdsToVotes < ActiveRecord::Migration[8.0]
  def change
    rename_column :votes, :project_id, :winner_id
    add_reference :votes, :loser, foreign_key: { to_table: :projects }
  end
end
