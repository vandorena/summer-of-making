class AddYswsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :ysws_submission, :boolean, default: false, null: false
    add_column :projects, :ysws_type, :string
  end
end
