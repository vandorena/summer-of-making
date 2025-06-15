class PullHighSeasStoriesFromAirtableJob < ApplicationJob
  queue_as :default

  def perform
    Airtable::HighSeasBook::StorySubmission.destructive_pull_all_from_airtable!
    sub = Airtable::HighSeasBook::StorySubmission.all
    sub.each do |submission|
      pic = submission.airtable_fields["Photos (Optional)"]
      next if pic.blank?
      pic.each do |photo|
        url = photo["url"]
        submission.attach_photo_from_url(url)
      end
    end
  end
end
