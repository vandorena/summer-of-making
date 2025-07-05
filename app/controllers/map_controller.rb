class MapController < ApplicationController
  before_action :authenticate_user!
  include MapHelper

  def index
    @projects_on_map = project_map_data(map_projects_query).to_json
    @placeable_projects = current_user.projects.joins(:ship_events).not_on_map.distinct.order(created_at: :desc)
  end

  def points
    render json: { projects: project_map_data(map_projects_query) }
  end
end
