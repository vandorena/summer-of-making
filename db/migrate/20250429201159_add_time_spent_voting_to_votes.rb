class AddTimeSpentVotingToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :time_spent_voting_ms, :integer
  end
end
