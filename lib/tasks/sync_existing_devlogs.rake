# frozen_string_literal: true

namespace :sync do
  desc 'Sync all existing devlogs to Airrecord'
  task devlogs: :environment do
    puts 'Starting to sync all devlogs to Airrecord...'

    total_devlogs = Devlog.count
    synced_count = 0
    failed_count = 0

    Devlog.find_each do |devlog|
      SyncDevlogToAirtableJob.perform_now(devlog.id)
      synced_count += 1
      print '.'
    rescue StandardError => e
      failed_count += 1
      puts "\nFailed to sync devlog #{devlog.id}: #{e.message}"
    end

    puts "\nSync completed!"
    puts "Total devlogs: #{total_devlogs}"
    puts "Successfully synced: #{synced_count}"
    puts "Failed to sync: #{failed_count}"
  end
end
