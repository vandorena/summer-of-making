module Api
  module V1
    class DevlogsController < ApplicationController
      def index
        @devlogs = Devlog.all.map do |devlog|
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
        render json: @devlogs
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
