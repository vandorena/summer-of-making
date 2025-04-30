class SyncVoteToAirtableJob < ApplicationJob
  queue_as :default

  def perform(vote_id)
    vote = Vote.find(vote_id)
    return unless vote

    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "votes")
    user_slack_id = User.find(vote.user_id).slack_id
    winner_project_id = vote.winner_id.to_s
    loser_project_id = vote.loser_id.to_s

    vote_data = {
      "explanation" => vote.explanation,
      "user_slack_id" => user_slack_id,
      "winner_project_id" => winner_project_id,
      "loser_project_id" => loser_project_id,
      "vote_id" => vote.id.to_s,
      "winner_demo_opened" => vote.winner_demo_opened,
      "winner_readme_opened" => vote.winner_readme_opened,
      "winner_repo_opened" => vote.winner_repo_opened,
      "loser_demo_opened" => vote.loser_demo_opened,
      "loser_readme_opened" => vote.loser_readme_opened,
      "loser_repo_opened" => vote.loser_repo_opened,
      "time_spent_voting_ms" => vote.time_spent_voting_ms,
      "music_played" => vote.music_played
    }

    existing_record = table.all(filter: "{vote_id} = '#{vote.id}'").first

    record = existing_record

    if existing_record
      updated = false
      vote_data.each do |field, new_value|
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(vote_data)
      record.save
    end

    return unless record&.id

    user_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "users")
    user_record = user_table.all(filter: "{slack_id} = '#{user_slack_id}'").first
    if user_record
      user_record["votes"] = (Array(user_record["votes"]) + [record.id]).uniq
      user_record.save
    end

    project_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "projects")
    winner_project_record = project_table.all(filter: "{project_id} = '#{winner_project_id}'").first
    if winner_project_record
      winner_project_record["votes_won"] = (Array(winner_project_record["votes_won"]) + [record.id]).uniq
      winner_project_record.save
    end

    if loser_project_id
      loser_project_record = project_table.all(filter: "{project_id} = '#{loser_project_id}'").first
      if loser_project_record
        loser_project_record["votes_lost"] = (Array(loser_project_record["votes_lost"]) + [record.id]).uniq
        loser_project_record.save
      end
    end
  end
end 