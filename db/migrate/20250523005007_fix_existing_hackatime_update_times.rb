class FixExistingHackatimeUpdateTimes < ActiveRecord::Migration[8.0]
  def up
    Project.includes(:updates).where("hackatime_project_keys IS NOT NULL").find_each do |project|
      updates_with_hackatime = project.updates
                                      .where.not(last_hackatime_time: nil)
                                      .order(:created_at)

      next if updates_with_hackatime.empty?

      previous_total = 0

      updates_with_hackatime.each do |update|
        current_total = update.last_hackatime_time
        actual_time_spent = current_total - previous_total

        # Update the record with the correct time spent for this specific update
        update.update_column(:last_hackatime_time, actual_time_spent)

        previous_total = current_total
      end
    end
  end
end
