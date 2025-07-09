# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < ApplicationController
      include Pagy::Backend

      def index
        pagy, projects = pagy(Project.all, items: 20)

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
            items: pagy.items
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
