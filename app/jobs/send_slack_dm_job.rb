# frozen_string_literal: true

class SendSlackDmJob < ApplicationJob
  queue_as :latency_5m

  def perform(user_id, message)
    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))

    channel_id = Rails.cache.fetch("slack_channel_id_#{user_id}", expires_in: 1.hour) do
      response = client.conversations_open(users: user_id)
      response.channel.id
    end

    client.chat_postMessage(
      channel: channel_id,
      text: message,
      as_user: true
    )
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Failed to send Slack DM: #{e.message}")
  end
end
