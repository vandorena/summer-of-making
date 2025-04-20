class SyncUpdateToAirtableJob < ApplicationJob
  queue_as :default

  def perform(update_id)
    update = Update.find(update_id)
    return unless update

    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "updates")
    author_slack_id = User.find(update.user_id).slack_id

    update_data = {
      "text" => update.text,
      "attachment_url" => update.attachment,
      "author_slack_id" => author_slack_id,
      "author_project_id" => update.project_id.to_s,
      "update_id" => update.id.to_s
    }

    existing_record = table.all(filter: "{update_id} = '#{update.id}'").first

    record = existing_record

    if existing_record
      updated = false
      %w[text attachment_url author_slack_id author_project_id update_id].each do |field|
        new_value = update_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(update_data)
      record.save
    end

    return unless record&.id

    project_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "projects")
    project = project_table.all(filter: "{project_id} = '#{update.project_id}'").first

    return unless project

    project["updates"] = Array(project["updates"]).map(&:to_s) + [ record.id.to_s ]
    project["updates"].uniq!
    project.save


    user_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "users")
    user = user_table.all(filter: "{slack_id} = '#{author_slack_id}'").first

    return unless user

    user["updates"] = Array(user["updates"]).map(&:to_s) + [ record.id.to_s ]
    user["updates"].uniq!
    user.save
  end
end
