class RemoveBannerFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :banner
  end
end
