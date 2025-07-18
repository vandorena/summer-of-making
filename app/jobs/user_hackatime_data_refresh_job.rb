# frozen_string_literal: true

# This refreshes every user's Hackatime Project data.
class UserHackatimeDataRefreshJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Starting")
    end

    User.find_each(&:refresh_hackatime_data_now)

    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Ended")
    end

    UserHackatimeDataRefreshJob.perform_later
  end
end
