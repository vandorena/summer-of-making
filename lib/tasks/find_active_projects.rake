namespace :projects do
  desc "Find projects with more than 10 updates spread across at least 5 different dates"
  task find_active: :environment do
    active_project_ids = Project.joins(:updates)
      .group('projects.id')
      .having('COUNT(updates.id) > 10')
      .having('COUNT(DISTINCT DATE(updates.created_at)) >= 5')
      .pluck('projects.id')

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
end 