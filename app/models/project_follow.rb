class ProjectFollow < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :user_id, uniqueness: { scope: :project_id, message: "is already following this project" }

  after_commit :sync_to_airtable, on: [:create]
  after_destroy :delete_from_airtable

  private

  def sync_to_airtable
    SyncProjectFollowToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteProjectFollowFromAirtableJob.perform_later(id)
  end
end
