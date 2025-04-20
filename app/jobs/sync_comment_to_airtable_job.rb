class SyncCommentToAirtableJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    puts "Syncing comment to airtable: #{comment_id}"
    comment = Comment.find(comment_id)
    return unless comment

    table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "comments")
    author_slack_id = User.find(comment.user_id).slack_id
    
    comment_data = {
      "comment_id" => comment.id.to_s,
      "author_slack_id" => author_slack_id,
      "update_id" => comment.update_id.to_s,
      "text" => comment.text,
    }

    existing_record = table.all(filter: "{comment_id} = '#{comment.id.to_s}'").first

    record = existing_record

    if existing_record
      updated = false
      %w[comment_id author_slack_id update_id text].each do |field|
        new_value = comment_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(comment_data)
      record.save
    end

    return unless record&.id

    update_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "updates")
    update = update_table.all(filter: "{update_id} = '#{comment.update_id.to_s}'").first

    return unless update

    update["comments"] = Array(update["comments"]).map(&:to_s) + [record.id.to_s]
    update["comments"].uniq!
    update.save

    user_table = Airrecord.table(ENV["AIRTABLE_API_KEY"], ENV["AIRTABLE_BASE_ID_JOURNEY"], "users")
    user = user_table.all(filter: "{slack_id} = '#{author_slack_id}'").first

    return unless user

    user["comments"] = Array(user["comments"]).map(&:to_s) + [record.id.to_s]
    user["comments"].uniq!
    user.save
  end
end 