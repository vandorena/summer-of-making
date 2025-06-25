class CreateVoteChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :vote_changes do |t|
      t.references :vote, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.integer :elo_before, null: false
      t.integer :elo_after, null: false
      t.integer :elo_delta, null: false
      t.string :result, null: false
      t.integer :project_vote_count, null: false

      t.timestamps
    end

    add_index :vote_changes, [ :project_id, :created_at ]
    add_index :vote_changes, :result
  end
end
