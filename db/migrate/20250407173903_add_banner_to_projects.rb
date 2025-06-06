class AddBannerToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :banner, :string
    execute "UPDATE projects SET banner = 'https://via.placeholder.com/1200x630?text=No+Banner'"
    change_column_null :projects, :banner, false
  end
end
