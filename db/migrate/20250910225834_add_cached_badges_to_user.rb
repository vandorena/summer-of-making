class AddCachedBadgesToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :badges, :string, array: true, default: []
  end
end
