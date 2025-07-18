class OneTime::FindAndProcessMissingGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform(dry_run: true)
    puts "=== Finding Projects Missing Genesis Payouts ==="
    puts "Dry run: #{dry_run ? 'YES' : 'NO'}"
    puts

    # Find projects that have:
    # 1. Ship events
    # 2. At least 18 votes after any ship event
    # 3. No existing payouts for their ship events
    projects_with_qualifying_ships = Project.joins(:ship_events, :vote_changes)
                                            .where("vote_changes.created_at > ship_events.created_at")
                                            .where("vote_changes.project_vote_count >= 18")
                                            .distinct

    # Get project IDs that have any payouts on ship events
    project_ids_with_payouts = Payout.where(payable_type: "ShipEvent")
                                     .joins("JOIN ship_events ON ship_events.id = payouts.payable_id")
                                     .distinct
                                     .pluck("ship_events.project_id")

    # Get projects without any payouts on ship events
    projects_without_payouts = projects_with_qualifying_ships.where.not(id: project_ids_with_payouts)

    puts "Found #{projects_without_payouts.count} projects with qualifying ship events but no payouts:"
    puts

    if projects_without_payouts.empty?
      puts "No projects need genesis payouts!"
      return
    end

    successful_projects = 0
    failed_projects = 0

    projects_without_payouts.find_each do |project|
      puts "Processing Project #{project.id}: #{project.title}"
      puts "  Ship events: #{project.ship_events.count}"
      puts "  Running SingleProjectGenesisPayoutJob..."

      begin
        OneTime::SingleProjectGenesisPayoutJob.perform_now(
          project_id: project.id,
          dry_run: dry_run
        )
        puts "  ✅ Job completed successfully"
        successful_projects += 1
      rescue => e
        puts "  ❌ Job failed: #{e.message}"
        failed_projects += 1
      end

      puts
    end

    puts "=== Processing Complete ==="
    puts "Successful: #{successful_projects}"
    puts "Failed: #{failed_projects}"

    if dry_run
      puts "This was a dry run. To actually execute payouts, run:"
      puts "OneTime::FindAndProcessMissingGenesisPayoutsJob.perform_now(dry_run: false)"
    end
  end
end
