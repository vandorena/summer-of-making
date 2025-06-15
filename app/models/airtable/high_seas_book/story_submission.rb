# == Schema Information
#
# Table name: airtable_high_seas_book_story_submissions
#
#  id              :bigint           not null, primary key
#  airtable_fields :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  airtable_id     :string
#
class Airtable::HighSeasBook::StorySubmission < ApplicationRecord
  # jsonb: airtable_fields
  # string: airtable_id

  include BackedByAirtable
  include AirtableImageStorage
  backed_by_filter "{Show in Summer of Making}"

  class AirtableRecord < Norairrecord::Table
    self.base_key = "appKexHWHYYVY1GFW"
    self.table_name = "tblGUy12HSqCXveg2"
    self.api_key = ENV["HIGHSEAS_AIRTABLE_KEY"]
  end

  has_many_attached :photos

  def attach_photo_from_url(url)
    return if url.blank?
    require "open-uri"
    file = URI.open(url)
    filename = File.basename(URI.parse(url).path)
    self.photos.attach(io: file, filename: filename)
  end

  def self.sync_with_airtable
    records = AirtableRecord.all
    count = 0
    records.each do |record|
      next unless record.id.present?
      submission = find_or_initialize_by(airtable_id: record.id)
      submission.airtable_fields = record.fields
      if submission.changed?
        submission.save!
        count += 1
      end
    end
    count
  end
end
