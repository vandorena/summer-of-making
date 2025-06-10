# frozen_string_literal: true

module Avo
  module Resources
    class ShopItem < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :type, as: :text
        field :name, as: :text
        field :description, as: :textarea
        field :internal_description, as: :text
        field :actual_irl_fr_cost, as: :number
        field :cost, as: :number
        field :hacker_score, as: :text
        field :requires_black_market, as: :boolean
        field :hcb_merchant_lock, as: :text
        field :hcb_category_lock, as: :text
        field :hcb_keyword_lock, as: :text
        field :agh_contents, as: :code
        field :image, as: :file
      end

    end
  end
end
