# frozen_string_literal: true

module Avo
  module Resources
    class MagicLink < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :user, as: :text
        field :token, as: :text
      end
    end
  end
end
