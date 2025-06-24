# frozen_string_literal: true

class SyncUserToAirtableJob < ApplicationJob
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
      "_users"
    )

    records = users_to_sync.map do |user|
      table.new({
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "email" => user.email,
        "slack_id" => user.slack_id,
        "avatar_url" => user.avatar,
        "has_commented" => user.has_commented,
        "is_admin" => user.is_admin,
        "hours" => user.hackatime_stat&.total_seconds_across_all_projects&.fdiv(3600),
        "verification_status" => user.verification_status.to_s,
        "created_at" => user.created_at,
        "synced_at" => Time.now,
        "som_id" => user.id
      })
    end

    table.batch_upsert(records, "slack_id")
  ensure
    users_to_sync.update_all(synced_at: Time.now)
  end

  private

  def users_to_sync
    @users_to_sync ||= User.includes(:hackatime_stat).order("synced_at ASC NULLS FIRST").limit(10)
  end
end
