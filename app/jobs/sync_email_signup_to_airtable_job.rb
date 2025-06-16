class SyncEmailSignupToAirtableJob < ApplicationJob
  queue_as :default

  def perform(signup_id)
    signup = EmailSignup.find(signup_id)
    return unless signup

    # Use Airrecord table
    table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                            Rails.application.credentials.airtable.base_id, "_email_signups")

    signup_data = {
      "email" => signup.email,
      "ip" => signup.ip,
      "user_agent" => signup.user_agent,
      "ref" => signup.ref,
      "created_at" => signup.created_at
    }

    existing_record = table.all(filter: "{email} = '#{signup.email}'").first

    if existing_record
      updated = false
      %w[email ip user_agent ref created_at].each do |field|
        new_value = signup_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(signup_data)
      record.save
    end
  end
end
