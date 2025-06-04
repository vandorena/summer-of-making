class AddIdentityToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :identity_vault_id, :string, if_not_exists: true
    add_column :users, :identity_vault_access_token, :string, if_not_exists: true
    add_column :users, :ysws_verified, :boolean, default: false, if_not_exists: true
  end
end
