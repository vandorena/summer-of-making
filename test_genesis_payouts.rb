#!/usr/bin/env ruby
# Test script to run genesis payouts in a transaction without committing
# This will generate a CSV with payout data for testing

require 'csv'

puts "Starting Genesis Payouts Test (DRY RUN - NO COMMITS)"
puts "=" * 60

# Start a transaction that we'll never commit
ActiveRecord::Base.transaction do
  puts "Starting transaction..."

  # Clear existing payouts to simulate fresh genesis run
  initial_payout_count = Payout.count
  puts "Initial payout count: #{initial_payout_count}"

  # Run the genesis job logic (similar to OneTime::InitiateGenesisPayoutsJob)
  puts "Running genesis payouts for all projects..."

  # Check if genesis has already been run
  if Payout.where(payable_type: "ShipEvent").any?
    puts "Genesis payouts have already been run. Clearing existing payouts for test..."
    Payout.where(payable_type: "ShipEvent").delete_all
  end

  # Track payouts created
  payouts_created = []

  # Find all projects and run issue_payouts(all_time: true)
  Project.find_each.with_index do |project, index|
    puts "Processing project #{index + 1}: #{project.title} (ID: #{project.id})"

    # Store payouts before
    payouts_before = Payout.count

    begin
      # Run the payout logic
      project.issue_payouts(all_time: true)

      # Check what payouts were created
      payouts_after = Payout.count
      new_payouts = payouts_after - payouts_before

      if new_payouts > 0
        puts "  Created #{new_payouts} payouts"

        # Get the newly created payouts for this project
        project_payouts = Payout.joins(:payable)
                               .where(payable: project.ship_events)
                               .where('payouts.id > ?', payouts_before)

        project_payouts.each do |payout|
          ship_event = payout.payable
          next unless ship_event.is_a?(ShipEvent)

          # Get project vote data at the time of payout calculation
          vote_count = VoteChange.where(project: project).maximum(:project_vote_count) || 0

          # Calculate ELO percentile and bounds
          min_elo, max_elo = if vote_count > 0
            Project.cumulative_elo_bounds_at_vote_count(vote_count)
          else
            [ project.rating, project.rating ]
          end

          elo_at_payout = project.rating
          elo_percentile = if min_elo == max_elo
            0.5
          else
            (elo_at_payout - min_elo) / (max_elo - min_elo).to_f
          end

          # Calculate payout per hour
          hours_covered = ship_event.respond_to?(:hours_covered) ? ship_event.hours_covered : 0
          payout_per_hour = hours_covered > 0 ? (payout.amount / hours_covered).round(2) : 0

          payouts_created << {
            id: payout.id,
            amount: payout.amount,
            payout_per_hour: payout_per_hour,
            elo_at_payout: elo_at_payout,
            elo_percentile: elo_percentile.round(4),
            elo_max: max_elo,
            elo_min: min_elo,
            project_id: project.id,
            project_title: project.title,
            ship_event_id: ship_event.id,
            hours_covered: hours_covered,
            vote_count: vote_count
          }
        end
      else
        puts "  No payouts created"
      end

    rescue => e
      puts "  ERROR: #{e.message}"
      puts "  #{e.backtrace.first}"
    end
  end

  puts "\nGenesis payouts completed!"
  puts "Total payouts that would be created: #{payouts_created.length}"
  puts "Total amount: $#{payouts_created.sum { |p| p[:amount] }}"

  # Generate CSV
  csv_filename = "genesis_payouts_test_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
  csv_path = Rails.root.join(csv_filename)

  CSV.open(csv_path, 'w', write_headers: true, headers: [
    'id', 'amount', 'payout_per_hour', 'elo_at_payout', 'elo_percentile',
    'elo_max', 'elo_min', 'project_id', 'project_title', 'ship_event_id',
    'hours_covered', 'vote_count'
  ]) do |csv|
    payouts_created.each do |payout_data|
      csv << [
        payout_data[:id],
        payout_data[:amount],
        payout_data[:payout_per_hour],
        payout_data[:elo_at_payout],
        payout_data[:elo_percentile],
        payout_data[:elo_max],
        payout_data[:elo_min],
        payout_data[:project_id],
        payout_data[:project_title],
        payout_data[:ship_event_id],
        payout_data[:hours_covered],
        payout_data[:vote_count]
      ]
    end
  end

  puts "\nCSV generated: #{csv_path}"
  puts "Sample data (first 5 rows):"
  puts "-" * 80

  payouts_created.first(5).each do |payout|
    puts "ID: #{payout[:id]}, Amount: $#{payout[:amount]}, " \
         "Per Hour: $#{payout[:payout_per_hour]}, ELO: #{payout[:elo_at_payout]} " \
         "(#{(payout[:elo_percentile] * 100).round(1)}%), Project: #{payout[:project_title]}"
  end

  # IMPORTANT: Rollback the transaction to avoid committing changes
  puts "\nRolling back transaction (no changes will be committed)..."
  raise ActiveRecord::Rollback
end

puts "\nTest completed successfully - no changes were committed to the database!"
