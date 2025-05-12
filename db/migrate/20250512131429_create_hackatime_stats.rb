class CreateHackatimeStats < ActiveRecord::Migration[8.0]
  def change
    create_table :hackatime_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :data, default: {}
      t.datetime :last_updated_at

      t.timestamps
    end
  end
end
