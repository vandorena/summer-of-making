class OneTime::ClearOutJob < ApplicationJob
  queue_as :default

  def perform(job_class)
    SolidQueue::Job.where(class_name: job_class.to_s, finished_at: nil).map do |j|
      j.discard
    rescue => e
      # Our job queue is currently running and some jobs WILL fail to discard due to race conditions– just ignore it for now
      Rails.logger.error "Failed to discard job #{j.id} (#{j.class_name})"
    end
  end
end

# ie. OneTime::ClearOutJob.perform_now(RefreshHackatimeStatsJob)
