class UpdateVotes < ActiveRecord::Migration[8.0]
  def change
    # Vote counter, but global
    add_column :votes, :vote_number, :integer
    add_index :votes, :vote_number, unique: true
    
    # Make winner_id nullable for ties
    change_column_null :votes, :winner_id, true
    rename_column :votes, :winner_id, :winning_project_id
    
    # Fraud/Invalid tracking
    add_column :votes, :status, :string, default: 'active', null: false
    add_column :votes, :invalid_reason, :text
    add_column :votes, :marked_invalid_at, :datetime
    add_reference :votes, :marked_invalid_by, foreign_key: { to_table: :users }
    
    add_index :votes, :status
    add_index :votes, :marked_invalid_at
  end
end