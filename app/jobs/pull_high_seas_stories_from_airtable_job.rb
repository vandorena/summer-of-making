class PullHighSeasStoriesFromAirtableJob < ApplicationJob
  queue_as :default

  def perform
    Airtable::HighSeasBook::StorySubmission.destructive_pull_all_from_airtable!
    sub = Airtable::HighSeasBook::StorySubmission.where("airtable_fields ->> 'Show in Summer of Making' = ?", "true")
    sub.each do |submission|
      photos_field = submission.airtable_fields["Photos (Optional)"]
      next if photos_field.blank?
      if submission.photos.attached?
        submission.photos.each do |photo|
          photo.purge
        end
        Rails.logger.info "exploded existing photos for #{submission.id}."
      end
      photos_field.each do |photo|
        url = photo["url"]
        submission.attach_photo_from_url(url)
      end
    end
  end
end
