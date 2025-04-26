namespace :users do
  desc "Update all users' Slack avatars from Slack API"
  task update_slack_avatars: :environment do
    puts "Starting Slack avatar update for all users..."
    UpdateSlackAvatarJob.perform_now
    puts "Slack avatar update completed."
  end
end
