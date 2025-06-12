class AddUaDetailsToEmailSignup < ActiveRecord::Migration[8.0]
  def change
    add_column :email_signups, :ip, :inet
    add_column :email_signups, :user_agent, :string
  end
end
