class OneTime::SingleProjectGenesisPayoutJob < ApplicationJob
  queue_as :default

  def perform(project_id:, dry_run: true)
    project = Project.find_by(id: project_id)

    unless project
      puts "ERROR: Project with ID #{project_id} not found!"
      return
    end

    puts "Processing genesis payouts for project #{project.id}: #{project.title}"
    puts "  Ship events: #{project.ship_events.count}"
    puts "  Vote changes: #{project.vote_changes.count}"

    # Check if project has qualifying ship events
    qualifying_ship_events = project.ship_events.joins(:project)
                                    .joins("JOIN vote_changes ON vote_changes.project_id = projects.id")
                                    .where("vote_changes.created_at > ship_events.created_at")
                                    .where("vote_changes.project_vote_count >= 18")
                                    .distinct

    if qualifying_ship_events.empty?
      puts "  No qualifying ship events (none have 18+ votes after creation)"
      return
    end

    puts "  Qualifying ship events: #{qualifying_ship_events.count}"

    ActiveRecord::Base.transaction do
      # Only delete payouts for this specific project's ship events
      existing_payouts = Payout.where(payable_type: "ShipEvent", payable_id: project.ship_events.pluck(:id))
      # puts "  Deleting #{existing_payouts.count} existing payouts for this project"
      # existing_payouts.delete_all
      raise "Existing payouts found for project #{project.id}: #{existing_payouts.count}" if existing_payouts.exists?

      # Process genesis payouts for this project
      project.issue_genesis_payouts

      new_payouts = Payout.where(payable_type: "ShipEvent", payable_id: project.ship_events.pluck(:id))
      puts "  Created #{new_payouts.count} new payouts"
      puts "  Total payout amount: $#{new_payouts.sum(:amount)}"

      if dry_run
        puts "  DRY RUN: Rolling back transaction"
        raise ActiveRecord::Rollback
      else
        puts "  SUCCESS: Payouts committed to database"
      end
    end
  end
end
