class AddIsBannedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_banned, :boolean, default: false
  end
end
