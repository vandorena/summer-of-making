# frozen_string_literal: true

class DeleteCommentFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    table = Airrecord.table(ENV.fetch('AIRTABLE_API_KEY', nil), ENV.fetch('AIRTABLE_BASE_ID_JOURNEY', nil), 'comments')
    record = table.all(filter: "{comment_id} = '#{comment_id}'").first
    return unless record

    record.destroy
  end
end
