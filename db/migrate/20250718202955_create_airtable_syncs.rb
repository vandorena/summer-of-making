class CreateAirtableSyncs < ActiveRecord::Migration[8.0]
  def change
    create_table :airtable_syncs do |t|
      t.references :syncable, polymorphic: true, null: false, index: true
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :airtable_syncs, [ :syncable_type, :syncable_id ], unique: true
    add_index :airtable_syncs, :last_synced_at
  end
end
