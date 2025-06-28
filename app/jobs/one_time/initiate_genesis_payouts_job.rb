class OneTime::InitiateGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    genesis_projects.each do |p|
      p.issue_payouts
    end
  end

  private

  def genesis_projects
    Project
      .joins(:ship_events)
      .group("projects.id")
      .having("MAX(ship_events.created_at) < ?", Vote::VOTING_START_DATE)
  end
end
