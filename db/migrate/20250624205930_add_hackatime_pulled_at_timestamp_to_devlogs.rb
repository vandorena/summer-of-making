class AddHackatimePulledAtTimestampToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :hackatime_pulled_at, :datetime
  end
end
