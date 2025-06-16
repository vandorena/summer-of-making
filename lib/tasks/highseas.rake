namespace :highseas do
  desc "Pull latest reviews from Airtable and download images"
  task refresh_reviews: :environment do
    puts "Syncing with Airtable..."

    begin
      sync_count = Airtable::HighSeasBook::StorySubmission.sync_with_airtable
      puts "Synced #{sync_count} records with Airtable"

      submissions = Airtable::HighSeasBook::StorySubmission.all
      if submissions.empty?
        puts "No reviews found in Airtable."
        next
      end
      puts "Found #{submissions.length} reviews."

      submissions.each do |submission|
        puts "\nProcessing review: #{submission.id}"
        puts "Available fields: #{submission.airtable_fields.keys.join(', ')}"
        photos = submission.airtable_fields["Photos (Optional)"]
        if photos.blank?
          puts "- No photos found, skipping..."
          next
        end
        begin
          photos.each do |photo|
            url = photo["url"]
            puts "- Downloading image from #{url} via active storage"
            submission.attach_photo_from_url(url)
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

  desc "Force refresh a specific review image by Airtable record ID"
  task :refresh_image, [ :record_id ] => :environment do |t, args|
    if args[:record_id].blank?
      puts "Please provide an Airtable record ID"
      next
    end
    puts "Refreshing image for record #{args[:record_id]}..."
    begin
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
        puts "Downloading image from #{url} via active storage"
        submission.attach_photo_from_url(url)
      end
    rescue StandardError => e
      puts "Error refreshing image: #{e.message}"
      puts "Error details: #{e.backtrace.first(5).join("\n  ")}"
      raise e
    end
  end
end
