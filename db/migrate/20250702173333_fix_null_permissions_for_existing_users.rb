class FixNullPermissionsForExistingUsers < ActiveRecord::Migration[8.0]
  def up
    # Update all users with null permissions to have an empty array
    execute "UPDATE users SET permissions = '[]' WHERE permissions IS NULL"
  end

  def down
    # No need to reverse this - we don't want to set permissions back to null
  end
end
