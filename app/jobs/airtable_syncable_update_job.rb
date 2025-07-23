class AirtableSyncableUpdateJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    sync_projects projects_to_sync
    sync_ship_events_for_projects projects_to_sync
  end

  private

  def sync_projects(projects)
    Rails.logger.info "Syncing #{projects.count} projects to Airtable"

    sync_records = projects.map(&:ensure_airtable_sync!)

    AirtableSyncJob.perform_now("Project", 10, sync_records)
  end

  def sync_ship_events_for_projects(projects)
    ship_events = projects.joins(:ship_events).includes(:ship_events).flat_map(&:ship_events)
    Rails.logger.info "Syncing #{ship_events.count} ship events for selected projects"

    ship_event_syncs = ship_events.map(&:ensure_airtable_sync!)

    ship_event_syncs.in_groups_of(10, false) do |batch|
      Rails.logger.info "Syncing batch of #{batch.count} ship events"
      AirtableSyncJob.perform_now("ShipEvent", 10, batch)
    end
  end

  def projects_to_sync
    @projects_to_sync ||= Project.includes(:ship_events).order(rating: :desc).limit(10)
  end
end
