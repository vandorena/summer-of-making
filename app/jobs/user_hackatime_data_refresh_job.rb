# frozen_string_literal: true

# This refreshes every user's Hackatime Project data.
class UserHackatimeDataRefreshJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  def perform
    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Starting")
    end

    User.where(has_hackatime: true).find_each do |user|
      # For batch processing: refresh data without caching
      user.refresh_hackatime_data_now!

      # Check for warnings and queue job if needed
      projects_needing_warnings = user.check_projects_needing_unlogged_warnings
      if projects_needing_warnings.any?
        UserHackatimeNotificationJob.perform_later(user.id, projects_needing_warnings.map(&:id))
      end
    end

    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Ended")
    end
  end
end
