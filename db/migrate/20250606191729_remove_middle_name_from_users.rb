class RemoveMiddleNameFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :middle_name
  end
end
