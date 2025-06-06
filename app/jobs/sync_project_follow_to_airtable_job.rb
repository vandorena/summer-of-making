# frozen_string_literal: true

class SyncProjectFollowToAirtableJob < ApplicationJob
  queue_as :default

  def perform(project_follow_id)
    Rails.logger.debug { "Syncing project follow to airtable: #{project_follow_id}" }
    project_follow = ProjectFollow.find(project_follow_id)
    return unless project_follow

    table = Airrecord.table(ENV.fetch("AIRTABLE_API_KEY", nil), ENV.fetch("AIRTABLE_BASE_ID_JOURNEY", nil),
                            "project_follows")
    author_slack_id = User.find(project_follow.user_id).slack_id

    project_follow_data = {
      "following_id" => project_follow.id.to_s,
      "author_slack_id" => author_slack_id,
      "project_id" => project_follow.project_id.to_s
    }

    existing_record = table.all(filter: "{following_id} = '#{project_follow.id}'").first

    record = existing_record

    if existing_record
      updated = false
      %w[following_id author_slack_id project_id].each do |field|
        new_value = project_follow_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(project_follow_data)
      record.save
    end

    return unless record&.id

    project_table = Airrecord.table(ENV.fetch("AIRTABLE_API_KEY", nil), ENV.fetch("AIRTABLE_BASE_ID_JOURNEY", nil),
                                    "projects")
    project = project_table.all(filter: "{project_id} = '#{project_follow.project_id}'").first

    return unless project

    project["followers"] = Array(project["followers"]).map(&:to_s) + [ record.id.to_s ]
    project["followers"].uniq!
    project.save

    user_table = Airrecord.table(ENV.fetch("AIRTABLE_API_KEY", nil), ENV.fetch("AIRTABLE_BASE_ID_JOURNEY", nil),
                                 "users")
    user = user_table.all(filter: "{slack_id} = '#{author_slack_id}'").first

    return unless user

    user["following"] = Array(user["following"]).map(&:to_s) + [ record.id.to_s ]
    user["following"].uniq!
    user.save
  end
end
