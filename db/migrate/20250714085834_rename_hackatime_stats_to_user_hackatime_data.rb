class RenameHackatimeStatsToUserHackatimeData < ActiveRecord::Migration[8.0]
  def change
    rename_table :hackatime_stats, :user_hackatime_data
  end
end
