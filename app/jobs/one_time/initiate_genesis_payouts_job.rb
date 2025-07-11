class OneTime::InitiateGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform(dry_run: false)
    # return if Payout.where(payable_type: "ShipEvent").any? # Protect from running twice

    ActiveRecord::Base.transaction do
      Payout.where(payable_type: "ShipEvent").delete_all
      
      # Find projects that have ship events and enough votes
      qualifying_projects = Project.joins(:ship_events, :vote_changes)
      .where(vote_changes: { project_vote_count: 18.. })
      .distinct
      # .limit(200)

      puts "Found #{qualifying_projects.count} qualifying projects"

      qualifying_projects.find_each do |p|
        puts "Processing project #{p.id}: #{p.title}"
        puts "  Ship events: #{p.ship_events.count}"

        p.issue_payouts(all_time: true)
      end

      total_payouts = Payout.where(payable_type: "ShipEvent").count
      puts "Total payouts created: #{total_payouts}"

      export_in_csv if dry_run
      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  def export_in_csv
    require "csv"

    # First collect all data to validate consistency
    payout_data = []
    vote_count_bounds = {}

    Payout.where(payable_type: "ShipEvent").find_each do |p|
      ship_event = p.payable
      project = ship_event.project

      # Get the cumulative vote count at the time this ship event was paid out
      # This should be the vote count when this ship event received its 18th vote
      votes_before_ship = VoteChange.where(project: project).where("created_at <= ?", ship_event.created_at).count

      # For genesis payouts, assume each qualifying ship event got exactly 18 votes
      # So cumulative count = votes before this ship + 18
      cumulative_vote_count_at_payout = votes_before_ship + 18

      # Use the new cumulative elo range method
      min, max = VoteChange.cumulative_elo_range_for_vote_count(cumulative_vote_count_at_payout)

      # Get the project's ELO at the specific target vote count (same logic as payout calculation)
      target_vote_count = votes_before_ship + 18
      vote_change_at_target = VoteChange.where(project: project, project_vote_count: target_vote_count).first
      current_elo = vote_change_at_target&.elo_after
      elo_percentile = min == max ? 0.0 : (current_elo - min) / (max - min).to_f

      # Check for consistency in bounds for same cumulative vote count
      if vote_count_bounds[cumulative_vote_count_at_payout]
        existing_min, existing_max = vote_count_bounds[cumulative_vote_count_at_payout]
        if existing_min != min || existing_max != max
          raise "INCONSISTENT ELO BOUNDS! Project #{project.id} with #{cumulative_vote_count_at_payout} cumulative votes has bounds [#{min}, #{max}] but previous project with same cumulative vote count had bounds [#{existing_min}, #{existing_max}]"
        end
      else
        vote_count_bounds[cumulative_vote_count_at_payout] = [ min, max ]
      end

      if min > current_elo || max < current_elo
        raise "INCONSISTENT ELO BOUNDS! Project #{project.id} with #{cumulative_vote_count_at_payout} cumulative votes has bounds [#{min}, #{max}] but current ELO is #{current_elo}"
      end

      payout_data << [
        project.title,
        project.id,
        ship_event.id,
        p.amount,
        current_elo,
        max,
        min,
        elo_percentile,
        cumulative_vote_count_at_payout,
        votes_before_ship
      ]
    end

    # If we get here, all bounds are consistent, so write the CSV
    CSV.open("genesis_payouts.csv", "w") do |csv|
      csv << [ "Project", "Project ID", "Ship ID", "Payout amount", "elo", "cumulative elo max", "cumulative elo min", "elo percentile", "ship event cumulative vote count", "votes before ship" ]
      payout_data.each { |row| csv << row }
    end

    puts "✅ ELO bounds consistency check passed!"
  end
end
