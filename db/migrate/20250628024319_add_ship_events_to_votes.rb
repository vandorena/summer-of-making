class AddShipEventsToVotes < ActiveRecord::Migration[8.0]
  def change
    add_reference :votes, :ship_event_1, null: false, foreign_key: { to_table: :ship_events }
    add_reference :votes, :ship_event_2, null: false, foreign_key: { to_table: :ship_events }
  end
end
