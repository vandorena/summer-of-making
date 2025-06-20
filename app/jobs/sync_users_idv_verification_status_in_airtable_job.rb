class SyncUsersIdvVerificationStatusInAirtableJob < ApplicationJob
  queue_as :default

  def perform
    table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                            Rails.application.credentials.airtable.base_id, "_users")

    User.find_each do |user|
      next if user.identity_vault_access_token.nil?
      current_status = user.fetch_idv&.[](:identity)&.[](:verification_status)

      existing_record = table.all(filter: "{slack_id} = '#{user.slack_id}'").first
      next if existing_record.nil?

      old_value = existing_record["verification_status"]
      existing_record["verification_status"] = current_status

      if old_value != current_status
        existing_record.save
        Rails.logger.tagged("SyncUsersIdvVerificationStatusInAirtableJob") do
          Rails.logger.info("Updated user #{user.id} from #{old_value || "jack shit"} to #{current_status}")
        end
      end
    end
  end
end
