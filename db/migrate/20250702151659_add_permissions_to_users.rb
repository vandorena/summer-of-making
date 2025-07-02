class AddPermissionsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :permissions, :text, default: "[]", null: false
  end
end
