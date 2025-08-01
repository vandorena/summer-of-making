module AirtableSyncable
  extend ActiveSupport::Concern

  included do
    has_one :airtable_sync, as: :syncable, dependent: :destroy
  end

  class_methods do
    def airtable_table_name(name = nil)
      if name
        @airtable_table_name = name
      else
        @airtable_table_name
      end
    end

    def airtable_field_mappings(mappings = nil)
      if mappings
        @airtable_field_mappings = mappings
      else
        @airtable_field_mappings || {}
      end
    end
  end

  def airtable_table_name
    self.class.airtable_table_name
  end

  def airtable_field_mappings
    self.class.airtable_field_mappings
  end

  def airtable_mapped_data
    airtable_field_mappings.transform_values do |field_path|
      field_path.split(".").reduce(self) { |obj, method| obj&.send(method) }
    end
  end

  def ensure_airtable_sync!
    airtable_sync || create_airtable_sync!
  end

  def airtable_record_id
    airtable_sync&.airtable_record_id
  end

  def airtable_synced?
    airtable_sync&.airtable_record_id.present?
  end
end
