class RecalculateDevlogTimeJob < ApplicationJob
  queue_as :default

  def perform(devlog_id)
    devlog = Devlog.find(devlog_id)

    prev_time = devlog.project
                      .devlogs
                      .where("created_at < ?", devlog.created_at)
                      .order(created_at: :desc)
                      .limit(1)
                      .pick(:created_at) || devlog.project.created_at

    bounded_prev_time = [ prev_time, devlog.created_at - 24.hours ].max

    res = devlog.user.fetch_raw_hackatime_stats(from: bounded_prev_time, to: devlog.created_at)
    data = JSON.parse(res.body)
    projects = data.dig("data", "projects")

    seconds_coded = projects
      .filter { |p| devlog.project.hackatime_project_keys.include?(p["name"]) }
      .reduce { |acc, h| acc.merge(seconds: acc["total_seconds"] + h["total_seconds"]) }

    Rails.logger.info "\tDevlog #{devlog_id} seconds coded: #{seconds_coded}"
    devlog.update!(seconds_coded:)
  end
end
