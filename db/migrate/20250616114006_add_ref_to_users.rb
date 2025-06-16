class AddRefToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :ref, :string
  end
end
