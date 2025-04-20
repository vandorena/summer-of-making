class DeleteProjectFollowFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(project_follow_id)
    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "project_follows")
    record = table.all(filter: "{following_id} = '#{project_follow_id}'").first
    return unless record

    record.destroy
  end
end
