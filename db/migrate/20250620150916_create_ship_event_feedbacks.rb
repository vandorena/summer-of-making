class CreateShipEventFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :ship_event_feedbacks do |t|
      t.references :ship_event, null: false, foreign_key: true
      t.string :comment

      t.timestamps
    end
  end
end
