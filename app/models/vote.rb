class Vote < ApplicationRecord
    belongs_to :user
    belongs_to :winner, class_name: "Project"
    belongs_to :loser, class_name: "Project"

    validates :explanation, presence: true, length: { minimum: 10 }
    validates :user_id, uniqueness: { scope: :winner_id, message: "has already voted for this project" }
    after_create :sync_to_airtable
    after_destroy :delete_from_airtable

    attr_accessor :token

    def authorized_with_token?(token_data)
        return false unless token_data

        token_data["user_id"] == user_id &&
        token_data["project_id"].to_s == winner_id.to_s &&
        Time.parse(token_data["expires_at"]) > Time.current
    end

    def sync_to_airtable
        SyncVoteToAirtableJob.perform_later(id)
    end

    def delete_from_airtable
        DeleteVoteFromAirtableJob.perform_later(id)
    end
end
