module Admin
  class SinkeningsController < ApplicationController
    def show
      @setting = SinkeningSetting.current
    end

    def update
      @setting = SinkeningSetting.current

      if @setting.update(intensity: params[:intensity])
        flash[:success] = "Sinkening intensity updated to #{@setting.intensity}"
      else
        flash[:error] = "Failed to update intensity: #{@setting.errors.full_messages.join(', ')}"
      end

      redirect_to admin_sinkening_path(@setting)
    end
  end
end
