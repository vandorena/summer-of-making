# frozen_string_literal: true

module Api
  module V1
    class EmotesController < ApplicationController
      def show
        emote_name = params[:id]
        emote = SlackEmote.find_by(name: emote_name)

        if emote
          render json: {
            name: emote.name,
            url: emote.url,
            html: emote.to_html
          }
        else
          render json: { error: "Emote not found" }, status: :not_found
        end
      end
    end
  end
end
