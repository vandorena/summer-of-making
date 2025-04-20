class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :update_record, class_name: "Update", foreign_key: "update_id"

  validates :text, presence: true

  after_create :notify_update_author
  after_commit :sync_to_airtable, on: [ :create ]
  after_destroy :delete_from_airtable
  private

  def notify_update_author
    return unless update_record.user.slack_id.present?

    message = "New comment on your project!:dino-bbq:\n\nCheck it out here: #{Rails.application.routes.url_helpers.project_url(update_record.project, host: ENV['APP_HOST'])}"
    SendSlackDmJob.perform_later(update_record.user.slack_id, message)
  end

  def sync_to_airtable
    SyncCommentToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteCommentFromAirtableJob.perform_later(id)
  end
end
