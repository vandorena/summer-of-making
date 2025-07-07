class AddViewCountsToProjectsAndDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :views_count, :integer, default: 0, null: false
    add_column :devlogs, :views_count, :integer, default: 0, null: false

    add_index :projects, :views_count
    add_index :devlogs, :views_count
  end
end
