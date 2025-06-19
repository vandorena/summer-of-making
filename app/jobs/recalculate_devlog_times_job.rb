class RecalculateDevlogTimesJob < ApplicationJob
  queue_as :default

  def perform
    Devlog.find_each(&:recalculate_seconds_coded)
  end
end
