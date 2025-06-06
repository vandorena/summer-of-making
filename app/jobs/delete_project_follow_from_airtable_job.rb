# frozen_string_literal: true

class DeleteProjectFollowFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(project_follow_id)
    table = Airrecord.table(ENV.fetch('AIRTABLE_API_KEY', nil), ENV.fetch('AIRTABLE_BASE_ID_JOURNEY', nil),
                            'project_follows')
    record = table.all(filter: "{following_id} = '#{project_follow_id}'").first
    return unless record

    record.destroy
  end
end
