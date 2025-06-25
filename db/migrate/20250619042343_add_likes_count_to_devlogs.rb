class AddLikesCountToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :likes_count, :integer, default: 0, null: false
  end
end
