class OneTime::InitiateGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform
    return if Payout.where(payable_type: "ShipEvent").any? # Protect from running twice

    ActiveRecord::Base.transaction do
      # Find projects that have ship events and enough votes
      qualifying_projects = Project.joins(:ship_events, :vote_changes)
      .where(vote_changes: { project_vote_count: 18.. })
      .distinct
      .limit(100)
      
      puts "Found #{qualifying_projects.count} qualifying projects"
      
      qualifying_projects.find_each do |p|
        puts "Processing project #{p.id}: #{p.title}"
        puts "  Ship events: #{p.ship_events.count}"
        
        p.issue_payouts(all_time: true)
      end

      total_payouts = Payout.where(payable_type: "ShipEvent").count
      puts "Total payouts created: #{total_payouts}"

      export_in_csv

      raise ActiveRecord::Rollback
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
      
      # Get ELO data using the same logic as payout calculation
      project_vote_count = VoteChange.where(project: project).count
      
      # Use the same logic as genesis payout calculation
      previous_changes = VoteChange.where("project_vote_count <= ?", project_vote_count)
      
      if previous_changes.any?
        min, max = Project.cumulative_elo_bounds(previous_changes)
        current_elo = VoteChange.where(project: project).order(:id).last&.elo_after || 1000
        elo_percentile = min == max ? 0.0 : (current_elo - min) / (max - min).to_f
      else
        min = max = current_elo = elo_percentile = 0
      end
      
      # Check for consistency in bounds for same vote count
      if vote_count_bounds[project_vote_count]
        existing_min, existing_max = vote_count_bounds[project_vote_count]
        if existing_min != min || existing_max != max
          raise "INCONSISTENT ELO BOUNDS! Project #{project.id} with #{project_vote_count} votes has bounds [#{min}, #{max}] but previous project with same vote count had bounds [#{existing_min}, #{existing_max}]"
        end
      else
        vote_count_bounds[project_vote_count] = [min, max]
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
        project_vote_count
      ]
    end

    # If we get here, all bounds are consistent, so write the CSV
    CSV.open("genesis_payouts.csv", "w") do |csv|
      csv << ["Project", "Project ID", "Ship ID", "Payout amount", "elo", "global elo max", "global elo min", "elo percentile", "project vote count"]
      payout_data.each { |row| csv << row }
    end
    
    puts "✅ ELO bounds consistency check passed!"
  end
end
