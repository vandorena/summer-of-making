# frozen_string_literal: true

module Api
  module V1
    class DevlogsController < ApplicationController
      include Pagy::Backend

      def index
        page = params[:page].to_i
        if page < 1
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        begin
          pagy, devlogs = pagy(Devlog.all.order(:id), items: 20, page: page) # order by id
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @devlogs = devlogs.map do |devlog|
          {
            text: devlog.text,
            id: devlog.id,
            attachment: devlog.attachment,
            project_id: devlog.project_id,
            slack_id: devlog.user.slack_id,
            created_at: devlog.created_at,
            updated_at: devlog.updated_at
          }
        end

        render json: {
          devlogs: @devlogs,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @devlog = Devlog.find(params[:id])
        render json: {
          text: @devlog.text,
          id: @devlog.id,
          attachment: @devlog.attachment,
          project_id: @devlog.project_id,
          slack_id: @devlog.user.slack_id,
          created_at: @devlog.created_at,
          updated_at: @devlog.updated_at
        }
      end
    end
  end
end
