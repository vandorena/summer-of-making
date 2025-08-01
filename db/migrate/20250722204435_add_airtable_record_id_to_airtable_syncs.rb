class AddAirtableRecordIdToAirtableSyncs < ActiveRecord::Migration[8.0]
  def change
    add_column :airtable_syncs, :airtable_record_id, :string
  end
end
