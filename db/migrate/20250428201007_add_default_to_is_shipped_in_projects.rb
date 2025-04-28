class AddDefaultToIsShippedInProjects < ActiveRecord::Migration[8.0]
  def change
    change_column_default :projects, :is_shipped, from: nil, to: false
  end
end
