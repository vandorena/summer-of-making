class UserHackatimeNotificationJob < ApplicationJob
  queue_as :literally_whenever

  WARNING_THRESHOLD = 9.hours.to_i
  MAXIMUM_THRESHOLD = 10.hours.to_i
  WARNING_COOLDOWN = 2.hours.to_i

  def perform(user_id, project_ids)
    @user = User.find(user_id)
    return unless @user.has_hackatime? && @user.user_hackatime_data.present?

    projects = @user.projects.includes(:devlogs).where(id: project_ids)

    projects.each do |project|
      begin
        unlogged_seconds = project.unlogged_time
        send_unlogged_warning_with_cache(project, unlogged_seconds)
      rescue => e
        Rails.logger.error "Failed to send unlogged time warning for project #{project.id} (#{project.title}): #{e.message}"
        Honeybadger.notify(e, context: {
          job: "UserHackatimeNotificationJob",
          project_id: project.id,
          project_title: project.title,
          user_id: @user.id,
          slack_id: @user.slack_id,
          hackatime_keys: project.hackatime_keys
        })
      end
    end
  end

  private

  def send_unlogged_warning_with_cache(project, unlogged_seconds)
    cache_key = "unlogged_time_warning:#{@user.id}:#{project.id}"

    unlogged_hours = (unlogged_seconds / 3600.0).round(1)
    remaining_hours = ((MAXIMUM_THRESHOLD - unlogged_seconds) / 3600.0).round(1)

    message = build_warning_message(project, unlogged_hours, remaining_hours)

    SendSlackDmJob.perform_later(@user.slack_id, message)
    Rails.cache.write(cache_key, Time.current.to_i, expires_in: WARNING_COOLDOWN)

    Rails.logger.info "Sent unlogged time warning to #{@user.display_name} for project '#{project.title}' - #{unlogged_hours}h unlogged"
  end

  def build_warning_message(project, unlogged_hours, remaining_hours)
    <<~MESSAGE.strip
      :siren-real: *Time to post a devlog!* :siren-real:#{' '}

      Your project *#{project.title}* has #{unlogged_hours} hours of unlogged coding time!

      You need to post a devlog before you reach 10 hours of unlogged time. If you exceed 10 hours of unlogged time, your overflowed time won't count towards your payout!

      📝 *#{remaining_hours} hours remaining* before you hit the limit.

      Head over to your project and create a devlog: #{project_url(project)}
    MESSAGE
  end

  def project_url(project)
    Rails.application.routes.url_helpers.project_url(project, host: "summer.hackclub.com")
  end
end
