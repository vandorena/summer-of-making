class AddUniqueIndexToEmailSignupsEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :email_signups, :email, unique: true
  end
end
