class RemoveRefFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :ref
  end
end
