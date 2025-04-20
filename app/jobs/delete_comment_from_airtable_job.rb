class DeleteCommentFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "comments")
    record = table.all(filter: "{comment_id} = '#{comment_id}'").first
    return unless record
    
    record.destroy
  end
end 