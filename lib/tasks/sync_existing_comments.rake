# frozen_string_literal: true

namespace :sync do
  desc "Sync all existing comments to Airrecord"
  task comments: :environment do
    puts "Starting to sync all comments to Airrecord..."

    total_comments = Comment.count
    synced_count = 0
    failed_count = 0

    Comment.find_each do |comment|
      SyncCommentToAirtableJob.perform_now(comment.id)
      synced_count += 1
      print "."
    rescue StandardError => e
      failed_count += 1
      puts "\nFailed to sync comment #{comment.id}: #{e.message}"
    end

    puts "\nSync completed!"
    puts "Total comments: #{total_comments}"
    puts "Successfully synced: #{synced_count}"
    puts "Failed to sync: #{failed_count}"
  end
end
