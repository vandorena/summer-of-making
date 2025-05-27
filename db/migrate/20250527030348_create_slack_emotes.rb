class CreateSlackEmotes < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_emotes do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :slack_id, null: false
      t.boolean :is_active, default: true, null: false
      t.string :created_by
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :slack_emotes, :name, unique: true
    add_index :slack_emotes, :slack_id, unique: true
  end
end
