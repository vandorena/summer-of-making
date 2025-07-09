# frozen_string_literal: true

namespace :devlogs do
  desc "Recalculate seconds_coded for devlogs with 0 duration_seconds"
  task recalculate_duration_seconds_without_cap: :environment do
    devlogs_to_update = Devlog.joins(:project)
                             .where(projects: { is_deleted: false })
                             .where(duration_seconds: 0)

    total_count = devlogs_to_update.count
    puts "Found #{total_count} devlogs with 0 duration_seconds"

    if total_count == 0
      puts "No devlogs need updating!"
      next
    end

    puts "Starting recalculation process..."
    updated_count = 0
    failed_count = 0

    devlogs_to_update.includes(:project, :user).find_each.with_index do |devlog, index|
      begin
        devlog.recalculate_seconds_coded
        updated_count += 1

        if (index + 1) % 50 == 0
          puts "Progress: #{index + 1}/#{total_count} processed, #{updated_count} updated, #{failed_count} failed"
        end
      rescue => e
        failed_count += 1
        puts "Failed to update devlog #{devlog.id}: #{e.message}"
      end
    end

    puts "Recalculation complete!"
    puts "Total devlogs processed: #{total_count}"
    puts "Total devlogs updated: #{updated_count}"
    puts "Total devlogs failed: #{failed_count}"
  end
end
