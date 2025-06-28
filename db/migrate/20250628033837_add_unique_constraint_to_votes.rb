class AddUniqueConstraintToVotes < ActiveRecord::Migration[8.0]
  def change
    # preventing replay attacks
    add_index :votes, [:user_id, :ship_event_1_id, :ship_event_2_id], 
              unique: true, 
              name: 'index_votes_on_user_and_ship_events'
  end
end
