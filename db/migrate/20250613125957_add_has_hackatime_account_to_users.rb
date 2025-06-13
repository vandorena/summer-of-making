class AddHasHackatimeAccountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :has_hackatime_account, :boolean
  end
end
