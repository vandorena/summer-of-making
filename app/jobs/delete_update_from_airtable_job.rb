class DeleteUpdateFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(update_id)
    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "updates")
    record = table.all(filter: "{update_id} = '#{update_id}'").first
    return unless record

    record.destroy
  end
end
