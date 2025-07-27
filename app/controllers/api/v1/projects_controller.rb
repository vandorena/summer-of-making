# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < ApplicationController
      include Pagy::Backend
      before_action :authenticate_user! # fucking over the api clients

      def index
        page = params[:page].to_i
        if page < 1
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        begin
          pagy, projects = pagy(
            Project.where(is_deleted: false)
                  .includes(:banner_attachment, :followers),
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @projects = projects.map do |project|
          {
            id: project.id,
            title: project.title,
            description: project.description,
            category: project.category,
            demo_link: project.demo_link,
            devlogs_count: project.devlogs_count,
            is_shipped: project.is_shipped,
            readme_link: project.readme_link,
            demo_link: project.demo_link,
            repo_link: project.repo_link,
            used_ai: project.used_ai,
            slack_id: project.user.slack_id,
            x: project.x,
            y: project.y,
            created_at: project.created_at,
            updated_at: project.updated_at
          }
        end

        render json: {
          projects: @projects,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @project = Project.find(params[:id])
        render json: {
          id: @project.id,
          title: @project.title,
          description: @project.description,
          category: @project.category,
          demo_link: @project.demo_link,
          devlogs_count: @project.devlogs_count,
          is_shipped: @project.is_shipped,
          readme_link: @project.readme_link,
          demo_link: @project.demo_link,
          repo_link: @project.repo_link,
          used_ai: @project.used_ai,
          x: @project.x,
          y: @project.y,
          created_at: @project.created_at,
          updated_at: @project.updated_at,
          slack_id: @project.user.slack_id,
        }
      end
    end
  end
end
