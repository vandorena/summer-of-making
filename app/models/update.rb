class Update < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy

  validates :text, presence: true

  # Attachment is a #cdn link
  validates :attachment, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true

  after_commit :sync_to_airtable, on: [ :create, :update ]
  after_destroy :delete_from_airtable

  private

  def sync_to_airtable
    SyncUpdateToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteUpdateFromAirtableJob.perform_later(id)
  end
end
