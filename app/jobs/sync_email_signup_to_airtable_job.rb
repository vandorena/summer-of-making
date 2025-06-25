# frozen_string_literal: true

class SyncEmailSignupToAirtableJob < ApplicationJob
  queue_as :literally_whenever

  # Prevent multiple jobs from being enqueued
  def self.perform_later(*args)
    return if SolidQueue::Job.where(class_name: name, finished_at: nil).exists?

    super
  end

  def perform
    table = Norairrecord.table(
      Rails.application.credentials.airtable.api_key,
      Rails.application.credentials.airtable.base_id,
      "_email_signups"
    )

    records = email_signups_to_sync.map do |email_signup|
      table.new({
        "email" => email_signup.email,
        "ip" => email_signup.ip,
        "user_agent" => email_signup.user_agent,
        "ref" => email_signup.ref,
        "created_at" => email_signup.created_at,
        "synced_at" => Time.now,
        "som_id" => email_signup.id
      })
    end

    table.batch_upsert(records, "email")
  ensure
    email_signups_to_sync.update_all(synced_at: Time.now)
  end

  private

  def email_signups_to_sync
    @email_signups_to_sync ||= EmailSignup.order("synced_at ASC NULLS FIRST").limit(10)
  end
end
