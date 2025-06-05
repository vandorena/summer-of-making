class TutorialProgressController < ApplicationController
  before_action :authenticate_user!

  def complete_step
    step_name = params[:step_name]

    if step_name.present?
      current_user.tutorial_progress.complete_step!(step_name)
      redirect_back(fallback_location: root_path, notice: "Tutorial step completed!")
    else
      redirect_back(fallback_location: root_path, alert: "Invalid step")
    end
  end
end
