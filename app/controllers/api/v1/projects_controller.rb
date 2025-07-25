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
          pagy, projects = pagy(Project.where(is_deleted: false), items: 20, page: page)
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
            readme_link: project.readme_link,
            demo_link: project.demo_link,
            repo_link: project.repo_link,
            slack_id: project.user.slack_id,
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
          readme_link: @project.readme_link,
          demo_link: @project.demo_link,
          repo_link: @project.repo_link,
          slack_id: @project.user.slack_id,
          created_at: @project.created_at,
          updated_at: @project.updated_at
        }
      end
    end
  end
end
