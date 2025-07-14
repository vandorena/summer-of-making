# frozen_string_literal: true

# This refreshes every user's Hackatime Project data.
class HackatimeStatRefreshJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    Rails.logger.tagged("HackatimeStatRefreshJob") do
      Rails.logger.info("Starting")
    end

    User.find_each(&:refresh_hackatime_data_now)

    Rails.logger.tagged("HackatimeStatRefreshJob") do
      Rails.logger.info("Ended")
    end

    HackatimeStatRefreshJob.perform_later
  end
end
