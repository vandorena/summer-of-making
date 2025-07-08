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

      @view_stats_by_date = calculate_view_stats_by_date(params[:interval])

      @average_views_per_project = @projects_with_views > 0 ? (@total_project_views.to_f / @projects_with_views).round(2) : 0
      @average_views_per_devlog = @devlogs_with_views > 0 ? (@total_devlog_views.to_f / @devlogs_with_views).round(2) : 0

      @recent_analytics = {
        projects_created_last_7_days: Project.where(created_at: 7.days.ago..Time.current).count,
        devlogs_created_last_7_days: Devlog.where(created_at: 7.days.ago..Time.current).count,
        total_projects: Project.count,
        total_devlogs: Devlog.count,
        project_views_last_24h: ViewEvent.for_projects.where("created_at >= ?", 24.hours.ago).count,
        devlog_views_last_24h: ViewEvent.for_devlogs.where("created_at >= ?", 24.hours.ago).count,
        total_views_last_24h: ViewEvent.for_projects.where("created_at >= ?", 24.hours.ago).count + ViewEvent.for_devlogs.where("created_at >= ?", 24.hours.ago).count
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

    def calculate_view_stats_by_date(interval = nil)
      interval ||= "1d"

      case interval
      when "1m"
        time_range = 2.hours.ago..Time.current
        group_method = :group_by_minute
        title = "total views by minute"
      when "5m"
        time_range = 6.hours.ago..Time.current
        group_method = :group_by_minute
        title = "total views by 5-minute intervals"
      when "15m"
        time_range = 12.hours.ago..Time.current
        group_method = :group_by_minute
        title = "total views by 15-minute intervals"
      when "30m"
        time_range = 24.hours.ago..Time.current
        group_method = :group_by_minute
        title = "total views by 30-minute intervals"
      when "1h"
        time_range = 48.hours.ago..Time.current
        group_method = :group_by_hour
        title = "total views by hour"
      when "2h"
        time_range = 4.days.ago..Time.current
        group_method = :group_by_hour
        title = "total views by 2-hour intervals"
      when "4h"
        time_range = 1.week.ago..Time.current
        group_method = :group_by_hour
        title = "total views by 4-hour intervals"
      when "6h"
        time_range = 2.weeks.ago..Time.current
        group_method = :group_by_hour
        title = "total views by 6-hour intervals"
      else # '1d'
        time_range = 30.days.ago..Time.current
        group_method = :group_by_day
        title = "total views by day"
      end

      project_views = ViewEvent.for_projects
                              .where(created_at: time_range)
                              .send(group_method, :created_at)
                              .count

      devlog_views = ViewEvent.for_devlogs
                             .where(created_at: time_range)
                             .send(group_method, :created_at)
                             .count

      # Combine views and apply interval grouping for minute-based intervals
      stats = {}

      if interval.ends_with?("m") && !interval.ends_with?("1m")
        # Group by intervals for minute-based views
        interval_minutes = interval.to_i

        project_views.each do |timestamp, count|
          # Round down to the nearest interval
          interval_timestamp = Time.at((timestamp.to_i / (interval_minutes * 60)) * (interval_minutes * 60))
          stats[interval_timestamp] ||= { project_views: 0, devlog_views: 0 }
          stats[interval_timestamp][:project_views] += count
        end

        devlog_views.each do |timestamp, count|
          interval_timestamp = Time.at((timestamp.to_i / (interval_minutes * 60)) * (interval_minutes * 60))
          stats[interval_timestamp] ||= { project_views: 0, devlog_views: 0 }
          stats[interval_timestamp][:devlog_views] += count
        end
      elsif interval.ends_with?("h") && !interval.ends_with?("1h")
        # Group by intervals for hour-based views
        interval_hours = interval.to_i

        project_views.each do |timestamp, count|
          interval_timestamp = Time.at((timestamp.to_i / (interval_hours * 3600)) * (interval_hours * 3600))
          stats[interval_timestamp] ||= { project_views: 0, devlog_views: 0 }
          stats[interval_timestamp][:project_views] += count
        end

        devlog_views.each do |timestamp, count|
          interval_timestamp = Time.at((timestamp.to_i / (interval_hours * 3600)) * (interval_hours * 3600))
          stats[interval_timestamp] ||= { project_views: 0, devlog_views: 0 }
          stats[interval_timestamp][:devlog_views] += count
        end
      else
        # For 1m, 1h, and 1d intervals, use direct grouping
        all_timestamps = (project_views.keys + devlog_views.keys).uniq

        all_timestamps.each do |timestamp|
          stats[timestamp] = {
            project_views: project_views[timestamp] || 0,
            devlog_views: devlog_views[timestamp] || 0
          }
        end
      end

      # Calculate total views for each timestamp
      stats.each do |timestamp, data|
        data[:total_views] = data[:project_views] + data[:devlog_views]
      end

      # Store the title for the chart
      @chart_title = title

      stats.sort.to_h
    end
  end
end
