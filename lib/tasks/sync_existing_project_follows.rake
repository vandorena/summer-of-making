# frozen_string_literal: true

namespace :sync do
  desc 'Sync all existing project follows to Airrecord'
  task project_follows: :environment do
    puts 'Starting to sync all project follows to Airrecord...'

    total_project_follows = ProjectFollow.count
    synced_count = 0
    failed_count = 0

    ProjectFollow.find_each do |project_follow|
      SyncProjectFollowToAirtableJob.perform_now(project_follow.id)
      synced_count += 1
      print '.'
    rescue StandardError => e
      failed_count += 1
      puts "\nFailed to sync project follow #{project_follow.id}: #{e.message}"
    end

    puts "\nSync completed!"
    puts "Total project follows: #{total_project_follows}"
    puts "Successfully synced: #{synced_count}"
    puts "Failed to sync: #{failed_count}"
  end
end
