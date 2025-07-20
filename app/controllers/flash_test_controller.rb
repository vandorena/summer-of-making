class FlashTestController < ApplicationController
  def test_notice
    flash[:notice] = "This is a success message! Your action was completed successfully."
    redirect_to request.referer || root_path
  end

  def test_alert
    flash[:alert] = "This is an error message! Something went wrong with your request."
    redirect_to request.referer || root_path
  end

  def test_both
    flash[:notice] = "Success: This action worked perfectly!"
    flash[:alert] = "Warning: But there's also something you should know about."
    redirect_to request.referer || root_path
  end
end
