# frozen_string_literal: true

module Admin
  class ViewAnalyticsController < ApplicationController
    def index
      @total_project_views = Project.sum(:views_count)
      @total_devlog_views = Devlog.sum(:views_count)
      @total_views = @total_project_views + @total_devlog_views

      @projects_with_views = Project.where("views_count > 0").count
      @devlogs_with_views = Devlog.where("views_count > 0").count

      @most_viewed_projects = Project.where("views_count > 0")
                                    .includes(:user)
                                    .order(views_count: :desc)
                                    .limit(10)

      @most_viewed_devlogs = Devlog.where("views_count > 0")
                                   .includes(:user, :project)
                                   .order(views_count: :desc)
                                   .limit(10)

      @top_viewed_users = calculate_top_viewed_users

      @view_stats_by_date = calculate_view_stats_by_date

      @average_views_per_project = @projects_with_views > 0 ? (@total_project_views.to_f / @projects_with_views).round(2) : 0
      @average_views_per_devlog = @devlogs_with_views > 0 ? (@total_devlog_views.to_f / @devlogs_with_views).round(2) : 0

      @recent_analytics = {
        projects_created_last_7_days: Project.where(created_at: 7.days.ago..Time.current).count,
        devlogs_created_last_7_days: Devlog.where(created_at: 7.days.ago..Time.current).count,
        total_projects: Project.count,
        total_devlogs: Devlog.count
      }
    end

    private

    def calculate_top_viewed_users
      project_views = Project.joins(:user)
                             .where("projects.views_count > 0")
                             .group("users.id", "users.display_name")
                             .sum("projects.views_count")

      devlog_views = Devlog.joins(:user)
                           .where("devlogs.views_count > 0")
                           .group("users.id", "users.display_name")
                           .sum("devlogs.views_count")

      user_views = {}

      project_views.each do |(user_id, display_name), views|
        user_views[user_id] = {
          id: user_id,
          display_name: display_name,
          project_views: views,
          devlog_views: 0,
          total_views: views
        }
      end

      devlog_views.each do |(user_id, display_name), views|
        if user_views[user_id]
          user_views[user_id][:devlog_views] = views
          user_views[user_id][:total_views] += views
        else
          user_views[user_id] = {
            id: user_id,
            display_name: display_name,
            project_views: 0,
            devlog_views: views,
            total_views: views
          }
        end
      end

      user_views.values.sort_by { |user| -user[:total_views] }.first(10)
    end

    def calculate_view_stats_by_date
      daily_project_views = ViewEvent.for_projects
                                    .recent(30)
                                    .group_by_day(:created_at)
                                    .count

      daily_devlog_views = ViewEvent.for_devlogs
                                   .recent(30)
                                   .group_by_day(:created_at)
                                   .count

      # Combine and fill missing dates
      all_dates = (30.days.ago.to_date..Date.current).to_a
      stats = {}

      all_dates.each do |date|
        stats[date] = {
          project_views: daily_project_views[date] || 0,
          devlog_views: daily_devlog_views[date] || 0
        }
        stats[date][:total_views] = stats[date][:project_views] + stats[date][:devlog_views]
      end

      stats
    end
  end
end
