# frozen_string_literal: true

class DeleteUpdateFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(update_id)
    table = Airrecord.table(ENV.fetch('AIRTABLE_API_KEY', nil), ENV.fetch('AIRTABLE_BASE_ID_JOURNEY', nil), 'updates')
    record = table.all(filter: "{update_id} = '#{update_id}'").first
    return unless record

    record.destroy
  end
end
