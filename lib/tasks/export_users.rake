# frozen_string_literal: true

namespace :export do
  desc "Export users to CSV with failsafe restart capability"
  task users: :environment do
    require "csv"

    output_file = File.join(Rails.root, "users_export.csv")
    progress_file = File.join(Rails.root, "users_export_progress.txt")

    # Read last processed ID from progress file
    last_id = 0
    if File.exist?(progress_file)
      last_id = File.read(progress_file).strip.to_i
      puts "Resuming from user ID #{last_id}"
    else
      puts "Starting fresh export"
    end

    # CSV headers
    headers = %w[
      slack_id first_name last_name email avatar_url
      has_commented is_admin hours created_at verification_status
    ]

    # Initialize CSV file if starting fresh
    if last_id == 0
      CSV.open(output_file, "w") do |csv|
        csv << headers
      end
    end

    batch_size = 100
    total_users = User.where("id > ?", last_id).count
    processed = 0

    puts "Processing #{total_users} users in batches of #{batch_size}"

    User.where("id > ?", last_id).find_in_batches(batch_size: batch_size) do |users|
      CSV.open(output_file, "a") do |csv|
        users.each do |user|
          begin
            # Calculate total hours from hackatime
            total_hours = 0
            if user.user_hackatime_data&.total_seconds_across_all_projects
              total_hours = (user.user_hackatime_data.total_seconds_across_all_projects / 3600.0).round(2)
            end

            # Get verification status safely
            verification_status = begin
              user.verification_status
            rescue => e
              Rails.logger.warn "Failed to get verification status for user #{user.id}: #{e.message}"
              "error"
            end

            row = [
              user.slack_id,
              user.first_name,
              user.last_name,
              user.email,
              user.avatar,
              user.has_commented,
              user.is_admin,
              total_hours,
              user.created_at&.iso8601,
              verification_status
            ]

            csv << row
            processed += 1

            # Update progress file every 10 records
            if processed % 10 == 0
              File.write(progress_file, user.id.to_s)
              puts "Processed #{processed}/#{total_users} users (#{(processed.to_f/total_users*100).round(1)}%)"
            end

          rescue => e
            Rails.logger.error "Error processing user #{user.id}: #{e.message}"
            puts "Error processing user #{user.id}: #{e.message}"
          end
        end
      end

      # Update progress after each batch
      File.write(progress_file, users.last.id.to_s)
    end

    # Cleanup progress file on completion
    File.delete(progress_file) if File.exist?(progress_file)

    puts "Export completed! File saved to: #{output_file}"
    puts "Total users exported: #{processed}"
  end
end
