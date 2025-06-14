namespace :highseas do
  desc "Pull latest reviews from Airtable and download images"
  task refresh_reviews: :environment do
    puts "Syncing with Airtable..."

    begin
      # First, sync with Airtable to get fresh data and URLs
      sync_count = Airtable::HighSeasBook::StorySubmission.sync_with_airtable
      puts "Synced #{sync_count} records with Airtable"

      # Now fetch all submissions with fresh data
      submissions = Airtable::HighSeasBook::StorySubmission.all

      if submissions.empty?
        puts "No reviews found in Airtable."
        next
      end

      puts "Found #{submissions.length} reviews."

      submissions.each do |submission|
        puts "\nProcessing review: #{submission.id}"

        # Debug line to see available fields
        puts "Available fields: #{submission.airtable_fields.keys.join(', ')}"

        photos = submission.airtable_fields["Photos (Optional)"]
        if photos.blank?
          puts "- No photos found, skipping..."
          next
        end

        begin
          # Photos field in Airtable returns an array of attachments
          photos.each do |photo|
            url = photo["url"]
            puts "- Downloading image from #{url}"
            local_path = submission.store_image_locally(url)
            if local_path
              puts "- Image downloaded successfully to #{local_path}"
            else
              puts "- Failed to download image"
            end
          end

        rescue StandardError => e
          puts "- Error downloading image: #{e.message}"
          puts "- Error details: #{e.backtrace.first(5).join("\n  ")}"
        end
      end

      puts "\nReview refresh completed!"

    rescue StandardError => e
      puts "Error refreshing reviews: #{e.message}"
      puts "Error details: #{e.backtrace.first(5).join("\n  ")}"
      raise e
    end
  end

  desc "Clean up old temporary High Seas review images"
  task cleanup_images: :environment do
    puts "Cleaning up old High Seas review images..."

    image_dir = Rails.root.join("public", "temp", "hsr")

    if Dir.exist?(image_dir)
      # Get all image files older than 30 days
      old_files = Dir.glob(File.join(image_dir, "*")).select do |f|
        File.file?(f) && File.mtime(f) < 30.days.ago
      end

      if old_files.any?
        puts "Found #{old_files.length} old image files"

        old_files.each do |file|
          begin
            File.delete(file)
            puts "- Deleted #{File.basename(file)}"
          rescue StandardError => e
            puts "- Error deleting #{File.basename(file)}: #{e.message}"
          end
        end

        puts "Cleanup completed!"
      else
        puts "No old image files found."
      end
    else
      puts "Image directory not found at #{image_dir}"
    end
  end

  desc "Force refresh a specific review image by Airtable record ID"
  task :refresh_image, [ :record_id ] => :environment do |t, args|
    if args[:record_id].blank?
      puts "Please provide an Airtable record ID"
      next
    end

    puts "Refreshing image for record #{args[:record_id]}..."

    begin
      # First sync with Airtable to get fresh URLs
      Airtable::HighSeasBook::StorySubmission.sync_with_airtable
      puts "Synced with Airtable"

      submission = Airtable::HighSeasBook::StorySubmission.find(args[:record_id])

      if submission.nil?
        puts "Review not found with ID: #{args[:record_id]}"
        next
      end

      photos = submission.airtable_fields["Photos (Optional)"]
      if photos.blank?
        puts "No photos found for this review"
        next
      end

      photos.each do |photo|
        url = photo["url"]
        puts "Downloading image from #{url}"
        local_path = submission.store_image_locally(url)
        if local_path
          puts "Image refreshed successfully to #{local_path}!"
        else
          puts "Failed to refresh image"
        end
      end

    rescue StandardError => e
      puts "Error refreshing image: #{e.message}"
      puts "Error details: #{e.backtrace.first(5).join("\n  ")}"
      raise e
    end
  end
end
