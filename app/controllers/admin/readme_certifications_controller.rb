module Admin
  class ReadmeCertificationsController < ApplicationController
    def index
      @readme_certifications = ReadmeCertification.includes(:project).order(updated_at: :asc)
    end

    def edit
      @readme_certification = ReadmeCertification.includes(project: :user).find(params[:id])
      @readme_certification.reviewer = current_user if @readme_certification.reviewer.nil?
    end

    def update
      @readme_certification = ReadmeCertification.find(params[:id])

      if @readme_certification.update(readme_certification_params)
        redirect_to admin_readme_certifications_path, notice: "README certification updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def readme_certification_params
      params.require(:readme_certification).permit(:judgement, :notes, :reviewer_id)
    end
  end
end
