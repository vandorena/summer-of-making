# frozen_string_literal: true

module Api
  module V1
    class CommentsController < ApplicationController
      include Pagy::Backend

      def index
        pagy, comments = pagy(Comment.all, items: 20)

        @comments = comments.map do |comment|
          {
            text: comment.content,
            devlog_id: comment.devlog_id,
            slack_id: comment.user.slack_id,
            created_at: comment.created_at
          }
        end

        render json: {
          comments: @comments,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.items
          }
        }
      end

      def show
        @comment = Comment.find(params[:id])
        render json: {
          text: @comment.content,
          devlog_id: @comment.devlog_id,
          slack_id: @comment.user.slack_id,
          created_at: @comment.created_at
        }
      end
    end
  end
end
