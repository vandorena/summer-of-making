# frozen_string_literal: true

namespace :devlogs do
  desc "Backfill empty hackatime_projects_key_snapshot with project's hackatime_project_keys"
  task backfill_hackatime_keys: :environment do
    puts "Finding devlogs with empty hackatime_projects_key_snapshot..."
    
    # Find devlogs with empty hackatime_projects_key_snapshot
    devlogs_to_update = Devlog.joins(:project)
                             .where("hackatime_projects_key_snapshot = '[]'")
                             .where.not(projects: { hackatime_project_keys: [] })
    
    total_count = devlogs_to_update.count
    puts "Found #{total_count} devlogs with empty hackatime_projects_key_snapshot that have projects with hackatime keys"
    
    if total_count == 0
      puts "No devlogs need updating!"
      next
    end
    
    puts "Starting backfill process..."
    updated_count = 0
    
    devlogs_to_update.includes(:project).find_each.with_index do |devlog, index|
      project_keys = devlog.project.hackatime_project_keys
      
      if project_keys.present?
        devlog.update_column(:hackatime_projects_key_snapshot, project_keys)
        updated_count += 1
        
        if (index + 1) % 100 == 0
          puts "Progress: #{index + 1}/#{total_count} processed, #{updated_count} updated"
        end
      end
    end
    
    puts "Backfill complete!"
    puts "Total devlogs processed: #{total_count}"
    puts "Total devlogs updated: #{updated_count}"
  end
  
  desc "Show statistics about devlog hackatime key snapshots"
  task stats_hackatime_keys: :environment do
    puts "Devlog Hackatime Key Statistics:"
    puts "=" * 50
    
    total_devlogs = Devlog.count
    empty_snapshots = Devlog.where("hackatime_projects_key_snapshot = '[]'").count
    non_empty_snapshots = total_devlogs - empty_snapshots
    
    puts "Total devlogs: #{total_devlogs}"
    puts "Devlogs with empty hackatime_projects_key_snapshot: #{empty_snapshots}"
    puts "Devlogs with populated hackatime_projects_key_snapshot: #{non_empty_snapshots}"
    
    # Check how many of the empty ones have projects with keys
    empty_with_project_keys = Devlog.joins(:project)
                                   .where("hackatime_projects_key_snapshot = '[]'")
                                   .where.not(projects: { hackatime_project_keys: [] })
                                   .count
    
    puts "Devlogs with empty snapshots but project has keys: #{empty_with_project_keys}"
    puts "Devlogs with empty snapshots and project has no keys: #{empty_snapshots - empty_with_project_keys}"
  end
end 