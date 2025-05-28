namespace :projects do
  desc "Find projects with more than 10 updates spread across at least 5 different dates"
  task find_active: :environment do
    active_project_ids = Project.joins(:updates)
      .group("projects.id")
      .having("COUNT(updates.id) > 10")
      .having("COUNT(DISTINCT DATE(updates.created_at)) >= 5")
      .pluck("projects.id")

    active_projects = Project.where(id: active_project_ids).includes(:updates)

    puts "\nFound #{active_projects.count} active projects:\n\n"

    active_projects.each do |project|
      update_dates = project.updates.map { |u| u.created_at.to_date }.uniq.sort
      puts "Project: #{project.title}"
      puts "Total updates: #{project.updates.count}"
      puts "Unique update dates: #{update_dates.count}"
      puts "Update dates: #{update_dates.join(', ')}"
      puts "----------------------------------------\n"
    end
  end

  desc "DM authors of active projects to ship their projects"
  task dm_active_authors: :environment do
    active_project_ids = Project.joins(:updates)
      .group("projects.id")
      .having("COUNT(updates.id) > 10")
      .having("COUNT(DISTINCT DATE(updates.created_at)) >= 5")
      .pluck("projects.id")

    active_projects = Project.where(id: active_project_ids).includes(:updates, :user)

    puts "\nSending DMs to authors of #{active_projects.count} active projects:\n\n"

    active_projects.each do |project|
      next unless project.user.slack_id.present?

      message = "Heya! You're receiving this DM because your project fulfills the primary criteria to be eligible for the giftcard. However, for your project to enter matchmaking, you need to ship it! Just click the Ship button on https://journey.hackclub.com/my_projects and make sure everything is valid. Then you're good to go"
      SendSlackDmJob.perform_later(project.user.slack_id, message)
      puts "Sent DM to #{project.user.display_name} about project: #{project.title}"
    end
  end
end
