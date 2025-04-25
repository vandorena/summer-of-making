class Update < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy

  validates :text, presence: true

  # Attachment is a #cdn link
  validates :attachment, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true

  # Validates if only MD changes are made
  validate :only_formatting_changes, on: :update

  after_commit :sync_to_airtable, on: [ :create, :update ]
  after_destroy :delete_from_airtable

  def formatted_text
    ApplicationController.helpers.markdown(text)
  end

  private

  def only_formatting_changes
    if text_changed? && persisted?
      original_stripped = strip_formatting(text_was)
      new_stripped = strip_formatting(text)

      if original_stripped != new_stripped
        errors.add(:text, "You can only modify formatting (markdown, spaces, line breaks), not the content")
      end
    end
  end

  def strip_formatting(text)
    return "" if text.nil?
    text.gsub(/[\s\n\r\t\*\_\#\~\`\>\<\-\+\.\,\;\:\!\?\(\)\[\]\{\}]/i, "").downcase
  end

  def sync_to_airtable
    SyncUpdateToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteUpdateFromAirtableJob.perform_later(id)
  end
end
