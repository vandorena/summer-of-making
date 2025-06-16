class AddRefToEmailSignups < ActiveRecord::Migration[8.0]
  def change
    add_column :email_signups, :ref, :string
  end
end
