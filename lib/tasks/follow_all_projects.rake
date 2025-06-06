# frozen_string_literal: true

namespace :projects do
  desc "Follow all projects for a given user ID"
  task :follow_all, [ :user_id ] => :environment do |_t, args|
    unless args[:user_id]
      puts "Error: User ID is required"
      puts "Usage: rake projects:follow_all[user_id]"
      exit 1
    end

    user = User.find_by(id: args[:user_id])
    unless user
      puts "Error: User with ID #{args[:user_id]} not found"
      exit 1
    end

    projects = Project.where.not(user_id: user.id)
    total_projects = projects.count
    followed = 0
    errors = []

    puts "Starting to follow #{total_projects} projects for user #{user.display_name} (ID: #{user.id})"

    projects.find_each do |project|
      next if user.project_follows.exists?(project_id: project.id)

      follow = user.project_follows.build(project: project)
      if follow.save
        followed += 1
        print "."
      else
        errors << "Failed to follow project #{project.id}: #{follow.errors.full_messages.join(', ')}"
        print "F"
      end
    end

    puts "\n\nResults:"
    puts "Total projects processed: #{total_projects}"
    puts "Successfully followed: #{followed}"
    puts "Already following: #{total_projects - followed - errors.size}"
    puts "Errors: #{errors.size}"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each { |error| puts "- #{error}" }
    end
  end
end
