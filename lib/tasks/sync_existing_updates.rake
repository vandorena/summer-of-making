namespace :sync do
  desc "Sync all existing updates to Airrecord"
  task updates: :environment do
    puts "Starting to sync all updates to Airrecord..."

    total_updates = Update.count
    synced_count = 0
    failed_count = 0

    Update.find_each do |update|
      begin
        SyncUpdateToAirtableJob.perform_now(update.id)
        synced_count += 1
        print "."
      rescue => e
        failed_count += 1
        puts "\nFailed to sync update #{update.id}: #{e.message}"
      end
    end

    puts "\nSync completed!"
    puts "Total updates: #{total_updates}"
    puts "Successfully synced: #{synced_count}"
    puts "Failed to sync: #{failed_count}"
  end
end
