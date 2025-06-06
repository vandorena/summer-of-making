# frozen_string_literal: true

namespace :active_storage do
  desc "Clean up unattached ActiveStorage blobs older than specified days (default: 7)"
  task :cleanup_unattached, [ :days ] => :environment do |_task, args|
    days = (args[:days] || 7).to_i

    puts "Cleaning up unattached ActiveStorage blobs older than #{days} days..."

    unattached_blobs = ActiveStorage::Blob.unattached.where(
      "created_at < ?", days.days.ago
    )

    count = unattached_blobs.count
    puts "Found #{count} unattached blobs to delete"

    if count > 0
      unattached_blobs.find_each do |blob|
        puts "Deleting blob: #{blob.filename} (#{blob.byte_size} bytes)"
        blob.purge
      end
      puts "Cleanup completed: #{count} blobs deleted"
    else
      puts "No unattached blobs found"
    end
  end
end
