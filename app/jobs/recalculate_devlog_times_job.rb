class RecalculateDevlogTimesJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    Devlog.find_each(&:recalculate_seconds_coded)
  end
end
