module BackedByAirtable
  extend ActiveSupport::Concern

  included do
    validates :airtable_fields, presence: true
    validates :airtable_id, presence: true, uniqueness: true
    attr_reader :filter
  end

  class_methods do
    def all_records
      self::AirtableRecord.records(filter: @filter)
    end

    def backed_by_filter(filter_by_formula)
      @filter = filter_by_formula
    end

    def has_airtable_attachment(airtable_field_name, attachment_name = :image)
      has_one_attached attachment_name, dependent: :destroy
      scope "has_attached_#{attachment_name}", -> { joins("#{attachment_name}_attachment".to_sym) }
      @airtable_attachments ||= []
      @airtable_attachments << { airtable_field_name: airtable_field_name, attachment_name: attachment_name }
    end

    def pull_all_from_airtable!
      all_records.each do |record|
        airtable_record = self.find_or_initialize_by(airtable_id: record.id)
        airtable_record.airtable_fields = record.fields
        @airtable_attachments.each do |attachment|
          raw_url = record.fields.dig(attachment[:airtable_field_name], 0, "url")
          filename = record.fields.dig(attachment[:airtable_field_name], 0, "filename")
          next unless raw_url
          image_uri = URI.parse(raw_url)
          downloaded_image = image_uri.open
          airtable_record.send(attachment[:attachment_name]).attach(io: downloaded_image, filename: filename)
        end
        airtable_record.save!
      end
    end

    def destructive_pull_all_from_airtable!
      self.transaction do
        self.delete_all
        self.pull_all_from_airtable!
      end
    end
  end
end
