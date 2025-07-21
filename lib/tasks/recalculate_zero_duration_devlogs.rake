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
    processed_count = 0
    successful_updates = []

    devlogs_to_update.includes(:project, :user).find_each do |devlog|
      processed_count += 1

      begin
        success = devlog.recalculate_seconds_coded

        if success
          updated_count += 1
          devlog.reload
          successful_updates << { id: devlog.id, duration: devlog.duration_seconds } if successful_updates.length < 10
          puts "[SUCCESS] Devlog #{devlog.id} updated to #{devlog.duration_seconds}s | Progress: #{processed_count}/#{total_count} | Updated: #{updated_count} | Failed: #{failed_count}"
        else
          failed_count += 1
          puts "[FAILED] Devlog #{devlog.id} - API call failed or no hackatime data | Progress: #{processed_count}/#{total_count} | Updated: #{updated_count} | Failed: #{failed_count}"
          puts "  User: #{devlog.user.email} (slack_id: #{devlog.user.slack_id})"
          puts "  Project: #{devlog.project.title}"
          puts "  Hackatime projects: #{devlog.hackatime_projects_key_snapshot}"
          puts "  Created: #{devlog.created_at}"
        end
      rescue => e
        failed_count += 1
        puts "[ERROR] Devlog #{devlog.id} raised exception: #{e.message}"
        puts "  User: #{devlog.user.email} (slack_id: #{devlog.user.slack_id})" if devlog.user
        puts "  Project: #{devlog.project.title}" if devlog.project
        puts "  Error details: #{e.class.name} - #{e.message}"
        puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
      end

      if processed_count % 100 == 0
        success_rate = (updated_count.to_f / processed_count * 100).round(1)
        puts "🔄 Progress: #{processed_count}/#{total_count} (#{(processed_count.to_f / total_count * 100).round(1)}%) | Success rate: #{success_rate}%"
      end
    end

    puts "Total devlogs processed: #{total_count}"
    puts "Successfully updated: #{updated_count} (#{(updated_count.to_f / total_count * 100).round(1)}%)"
    puts "Failed to update: #{failed_count} (#{(failed_count.to_f / total_count * 100).round(1)}%)"
  end
end
