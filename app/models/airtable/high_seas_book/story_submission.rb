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
    filename = File.basename(URI.parse(url).path)
    unless self.persisted?
      Rails.logger.error "StorySubmission #{self.id || 'no clue'} not persisted. Cannot attach #{filename}"
      self.save!
    end
    if self.photos.attached? && self.photos.any? { |att| att.filename.to_s == filename }
      Rails.logger.info "#{filename} already attached to StorySubmission #{self.id}, skipping."
      return
    end
    begin
      file = URI.open(url)
      self.photos.attach(io: file, filename: filename)
      self.save!
      Rails.logger.info "attach photo #{filename} to StorySubmission #{self.id}."
    rescue => e
      Rails.logger.error "fucked up '#{url}' to StorySubmission #{self.id} #{e.message}"
    end
  end

  def self.sync_with_airtable
    records = AirtableRecord.all.select { |record| record.fields["Show in Summer of Making"] == true }
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
