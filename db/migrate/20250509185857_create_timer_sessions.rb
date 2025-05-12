class CreateTimerSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :timer_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :update, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :last_paused_at
      t.integer :accumulated_paused, default: 0, null: false
      t.datetime :stopped_at
      t.integer :net_time, default: 0, null: false
      t.integer :status, null: false, default: 0 # enum: 0==running, 1==paused, 2==stopped (For my own sake https://api.rubyonrails.org/v5.2.4.5/classes/ActiveRecord/Enum.html)
      t.timestamps
    end
  end
end
