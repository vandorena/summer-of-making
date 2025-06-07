module Admin
  class UsersController < ApplicationController
    before_action :set_user

    layout false

    def internal_notes
      @user.internal_notes = params[:internal_notes]
      @user.save!
      render :internal_notes
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end