# frozen_string_literal: true

class DeleteVoteFromAirtableJob < ApplicationJob
  queue_as :default

  def perform(vote_id)
    table = Airrecord.table(ENV.fetch("AIRTABLE_API_KEY", nil), ENV.fetch("AIRTABLE_BASE_ID_JOURNEY", nil), "votes")

    records = table.all(filter: "{vote_id} = '#{vote_id}'")

    records.each(&:destroy)
  end
end
