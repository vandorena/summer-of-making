class AddDevlogsCountToProjects < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:projects, :devlogs_count)
      add_column :projects, :devlogs_count, :integer, default: 0, null: false

      reversible do |dir|
        dir.up do
          execute <<-SQL
            UPDATE projects SET devlogs_count = (
              SELECT COUNT(*)
              FROM devlogs
              WHERE devlogs.project_id = projects.id
            )
          SQL
        end
      end
    end
  end
end
