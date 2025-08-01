class AirtableCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting Airtable cleanup - clearing all invalid airtable_record_ids"

    cleared_count = AirtableSync.where.not(airtable_record_id: nil).count
    AirtableSync.update_all(airtable_record_id: nil)

    Rails.logger.info "Cleared #{cleared_count} airtable_record_ids"
    Rails.logger.info "Next sync will rebuild all Airtable relationships from scratch"
  end
end
