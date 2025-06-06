# frozen_string_literal: true

class SyncSlackEmotesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting Slack emotes sync..."

    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))

    begin
      response = client.emoji_list
      emotes_data = response.emoji

      Rails.logger.info "Found #{emotes_data.size} emotes from Slack"

      synced_count = 0
      created_count = 0
      updated_count = 0

      emotes_data.each do |name, url|
        # Skipping aliases (did you know that slack has aliases for emotes?)
        next if url.start_with?("alias:")

        emote = SlackEmote.find_or_initialize_by(name: name)

        if emote.new_record?
          emote.assign_attributes(
            url: url,
            slack_id: name,
            is_active: true,
            created_by: "sync_job",
            last_synced_at: Time.current
          )
          emote.save!
          created_count += 1
          Rails.logger.debug { "Created emote: #{name}" }
        else
          emote.update!(
            url: url,
            is_active: true,
            last_synced_at: Time.current
          )
          updated_count += 1
          Rails.logger.debug { "Updated emote: #{name}" }
        end

        synced_count += 1
      end

      Rails.logger.info "Slack emotes sync completed successfully!"
      Rails.logger.info "Total synced: #{synced_count}, Created: #{created_count}, Updated: #{updated_count}, Inactive: #{inactive_count}"
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Slack API error during emotes sync: #{e.message}"
      raise e
    rescue StandardError => e
      Rails.logger.error "Unexpected error during emotes sync: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
