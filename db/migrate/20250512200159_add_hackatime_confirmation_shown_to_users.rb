class AddHackatimeConfirmationShownToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :hackatime_confirmation_shown, :boolean, default: false
  end
end
