class AddIsShippedToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :is_shipped, :boolean
  end
end
