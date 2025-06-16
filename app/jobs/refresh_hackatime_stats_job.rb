# frozen_string_literal: true

class RefreshHackatimeStatsJob < ApplicationJob
  queue_as :default

  def perform(user_id, options = {})
    user = User.find_by(id: user_id)
    return unless user&.has_hackatime

    start_date = Time.use_zone("America/New_York") do
      Time.parse("2025-06-16").beginning_of_day
    end
    uri = URI("https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?features=projects&start_date=#{start_date}")

    response = Faraday.get(uri.to_s)
    return unless response.success?

    result = JSON.parse(response.body)

    stats = user.hackatime_stat || user.build_hackatime_stat
    stats.update(data: result, last_updated_at: Time.current)
  end
end
