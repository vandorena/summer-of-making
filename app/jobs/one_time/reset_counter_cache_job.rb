class OneTime::ResetCounterCacheJob < ApplicationJob
  queue_as :default

  def perform
    Devlog.find_each do |devlog|
      Devlog.reset_counters(devlog.id, :comments)
      Devlog.reset_counters(devlog.id, :likes)
    end
  end
end
