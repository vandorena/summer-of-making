# frozen_string_literal: true

namespace :export do
  desc "Export email signups to CSV with failsafe restart capability"
  task email_signups: :environment do
    require 'csv'

    output_file = File.join(Rails.root, 'email_signups_export.csv')
    progress_file = File.join(Rails.root, 'email_signups_export_progress.txt')

    # Read last processed ID from progress file
    last_id = 0
    if File.exist?(progress_file)
      last_id = File.read(progress_file).strip.to_i
      puts "Resuming from email signup ID #{last_id}"
    else
      puts "Starting fresh export"
    end

    # CSV headers
    headers = %w[ email ip user_agent ref created_at ]

    # Initialize CSV file if starting fresh
    if last_id == 0
      CSV.open(output_file, 'w') do |csv|
        csv << headers
      end
    end

    batch_size = 1000
    total_email_signups = EmailSignup.where('id > ?', last_id).count
    processed = 0

    puts "Processing #{total_email_signups} email signups in batches of #{batch_size}"

    EmailSignup.where('id > ?', last_id).find_in_batches(batch_size:) do |email_signups|
      CSV.open(output_file, 'a') do |csv|
        email_signups.each do |email_signup|
          begin
            row = [
              email_signup.email,
              email_signup.ip,
              email_signup.user_agent,
              email_signup.ref,
              email_signup.created_at&.iso8601
            ]

            csv << row
            processed += 1

            # Update progress file every 10 records
            if processed % 10 == 0
              File.write(progress_file, email_signup.id.to_s)
              puts "Processed #{processed}/#{total_email_signups} email signups (#{(processed.to_f/total_email_signups*100).round(1)}%)"
            end

          rescue => e
            Rails.logger.error "Error processing email signup #{email_signup.id}: #{e.message}"
            puts "Error processing email signup #{email_signup.id}: #{e.message}"
          end
        end
      end

      # Update progress after each batch
      File.write(progress_file, email_signups.last.id.to_s)
    end

    # Cleanup progress file on completion
    File.delete(progress_file) if File.exist?(progress_file)

    puts "Export completed! File saved to: #{output_file}"
    puts "Total email signups exported: #{processed}"
  end
end
