# frozen_string_literal: true

module Admin
  class ShopOrdersController < ApplicationController

    before_action :set_shop_order, only: [:show]

    def index
    end

    def pending
      render :index, locals: { title: "pending " }
    end

    def show

    end

    private

    def set_shop_order
      @shop_order = nil
    end
  end
end