class DeleteVoteFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(vote_id)
    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "votes")

    records = table.all(filter: "{vote_id} = '#{vote_id}'")

    records.each do |record|
      record.destroy
    end
  end
end
