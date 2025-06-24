class RecalculateDevlogTimesJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    devlogs_to_update.find_each(&:recalculate_seconds_coded)
  end

  private

  def devlogs_to_update
    @devlogs_to_update ||= Devlog.order("hackatime_pulled_at ASC NULLS FIRST").limit(20)
  end
end
