class OneTime::CleanupDuplicateShipEventsJob < ApplicationJob
  queue_as :default

  def perform(dry_run: true)
    ActiveRecord::Base.transaction do
      # Find projects with more than one ship event
      projects_with_multiple_ships = Project.joins(:ship_events)
                                           .group("projects.id")
                                           .having("COUNT(ship_events.id) > 1")

      puts "Found #{projects_with_multiple_ships.count} projects with multiple ship events"

      projects_with_multiple_ships.find_each do |project|
        puts "Processing project #{project.id}: #{project.title}"
        
        # Get ship events ordered by creation time
        ship_events = project.ship_events.order(:created_at)
        puts "  Ship events: #{ship_events.pluck(:id, :created_at)}"
        
        # Check each pair of consecutive ship events
        ship_events.each_cons(2) do |earlier_ship, later_ship|
          # Count votes between these ship events
          votes_between = VoteChange.where(project: project)
                                    .where("created_at > ?", earlier_ship.created_at)
                                    .where("created_at <= ?", later_ship.created_at)
                                    .count
          
          puts "  Between ship #{earlier_ship.id} and #{later_ship.id}: #{votes_between} votes"
          
          if votes_between < 18
            puts "    DELETING ship #{earlier_ship.id} - only #{votes_between} votes before next ship event"
            
            # Reassign votes from earlier ship to later ship
            votes_referencing_ship1 = Vote.where(ship_event_1_id: earlier_ship.id)
            votes_referencing_ship2 = Vote.where(ship_event_2_id: earlier_ship.id)
            
            if votes_referencing_ship1.any?
              puts "      Reassigning #{votes_referencing_ship1.count} votes (ship_event_1_id) from ship #{earlier_ship.id} to ship #{later_ship.id}"
              votes_referencing_ship1.update_all(ship_event_1_id: later_ship.id)
            end
            
            if votes_referencing_ship2.any?
              puts "      Reassigning #{votes_referencing_ship2.count} votes (ship_event_2_id) from ship #{earlier_ship.id} to ship #{later_ship.id}"
              votes_referencing_ship2.update_all(ship_event_2_id: later_ship.id)
            end
            
            # Now we can safely delete the ship event
            earlier_ship.destroy!
          end
        end
      end

      puts "Cleanup complete!"
      
      raise ActiveRecord::Rollback if dry_run
    end
  end
end
