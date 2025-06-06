# frozen_string_literal: true

namespace :active_storage do
  desc "Clean up unattached ActiveStorage blobs older than specified days (default: 7)"
  task :cleanup_unattached, [ :days ] => :environment do |_task, args|
    days = (args[:days] || 7).to_i

    puts "Cleaning up unattached ActiveStorage blobs older than #{days} days..."

    count = 0
    ActiveStorage::Blob
      .unattached
      .where(created_at: ..days.days.ago)
      .find_each do |blob|
        blob.purge_later
        count += 1
      end

    puts "Cleanup queued: #{count} blobs scheduled for deletion"
  end
end
