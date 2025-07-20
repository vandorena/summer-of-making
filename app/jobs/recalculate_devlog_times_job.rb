class RecalculateDevlogTimesJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  def perform
    devlogs_to_update.each(&:recalculate_seconds_coded)
  end

  private

  def devlogs_to_update
    Devlog.joins(:project)
          .where(projects: { is_deleted: false })
          .order("hackatime_pulled_at NULLS FIRST, hackatime_pulled_at ASC")
          .limit(60)
  end
end
