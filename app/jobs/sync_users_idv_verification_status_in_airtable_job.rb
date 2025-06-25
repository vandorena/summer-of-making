class SyncUsersIdvVerificationStatusInAirtableJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.tagged("SyncUsersIdvVerificationStatusInAirtableJob") do
      table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                              Rails.application.credentials.airtable.base_id, "_users")

      User.find_each do |user|
        if user.identity_vault_access_token.nil?
          Rails.logger.info("Skipped #{user.id} (no idv access token)")
          next
        end

        current_status = user.fetch_idv&.[](:identity)&.[](:verification_status)

        existing_record = table.all(filter: "{slack_id} = '#{user.slack_id}'").first
        if existing_record.nil?
          Rails.logger.info("Skipped #{user.id} (no record)")
          next
        end

        old_value = existing_record["verification_status"]
        existing_record["verification_status"] = current_status

        if old_value != current_status
          existing_record.save
          Rails.logger.info("Updated user #{user.id} from #{old_value || "jack shit"} to #{current_status}")
        else
          Rails.logger.info("Skipped #{user.id} (same status)")
        end
      end
    end
  end
end
