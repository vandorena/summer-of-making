class MapController < ApplicationController
  before_action :authenticate_user!

  def index
    # Manually construct a JSON payload with all necessary data
    @projects_on_map = Project.joins(:ship_events).on_map.includes(:user, :devlogs).distinct.map do |project|
      {
        id: project.id,
        x: project.x,
        y: project.y,
        title: project.title,
        user_id: project.user_id,
        devlogs_count: project.devlogs.count,
        total_time_spent: view_context.format_seconds(project.hackatime_total_time),
        project_path: project_path(project),
        user: {
          display_name: project.user.display_name,
          avatar: url_for(project.user.avatar)
        }
      }
    end.to_json

    @placeable_projects = current_user.projects.joins(:ship_events).not_on_map.distinct.order(created_at: :desc)
  end
end
