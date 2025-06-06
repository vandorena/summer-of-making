# frozen_string_literal: true

class SyncUpdateToAirtableJob < ApplicationJob
  queue_as :default

  def perform(devlog_id)
    devlog = Devlog.find(devlog_id)
    return unless devlog

    table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                            Rails.application.credentials.airtable.base_id, '_devlogs')
    author_slack_id = User.find(devlog.user_id).slack_id

    devlog_data = {
      'text' => devlog.text,
      'attachment_url' => devlog.attachment,
      'author_slack_id' => author_slack_id,
      'author_project_id' => devlog.project_id.to_s,
      'devlog_id' => devlog.id.to_s
    }

    existing_record = table.all(filter: "{devlog_id} = '#{devlog.id}'").first

    record = existing_record

    if existing_record
      updated = false
      %w(text attachment_url author_slack_id author_project_id devlog_id).each do |field|
        new_value = devlog_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(devlog_data)
      record.save
    end

    return unless record&.id

    project_table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                                    Rails.application.credentials.airtable.base_id, '_devlogs')
    project = project_table.all(filter: "{project_id} = '#{devlog.project_id}'").first

    return unless project

    project['devlogs'] = Array(project['devlogs']).map(&:to_s) + [record.id.to_s]
    project['devlogs'].uniq!
    project.save

    user_table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                                 Rails.application.credentials.airtable.base_id, '_users')
    user = user_table.all(filter: "{slack_id} = '#{author_slack_id}'").first

    return unless user

    user['devlogs'] = Array(user['devlogs']).map(&:to_s) + [record.id.to_s]
    user['devlogs'].uniq!
    user.save
  end
end
