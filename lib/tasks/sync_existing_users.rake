# frozen_string_literal: true

namespace :sync do
  desc "Sync all existing users to Airrecord"
  task users: :environment do
    puts "Starting to sync all users to Airrecord..."

    total_users = User.count
    synced_count = 0
    failed_count = 0

    User.find_each do |user|
      SyncUserToAirtableJob.perform_now(user.id)
      synced_count += 1
      print "."
    rescue StandardError => e
      failed_count += 1
      puts "\nFailed to sync user #{user.id}: #{e.message}"
    end

    puts "\nSync completed!"
    puts "Total users: #{total_users}"
    puts "Successfully synced: #{synced_count}"
    puts "Failed to sync: #{failed_count}"
  end
end
