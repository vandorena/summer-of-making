class RenameTimeWorkedToDurationSecondsInDevlogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :devlogs, :time_worked, :duration_seconds
  end
end
