module Api
  module V1
    class EmotesController < ApplicationController
      def show
        emote_name = params[:id]
        emote = SlackEmote.find_by_name(emote_name)

        if emote
          render json: {
            name: emote.name,
            url: emote.url,
            html: emote.to_html
          }
        else
          render json: { error: "Emote not found" }, status: 404
        end
      end
    end
  end
end
