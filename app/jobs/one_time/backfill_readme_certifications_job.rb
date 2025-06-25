class OneTime::BackfillReadmeCertificationsJob < ApplicationJob
  queue_as :default

  def perform
    # Find projects with readme_link but no readme_certifications
    # Using a subquery to avoid default_scope issues
    project_ids_needing_certification = Project.where.not(readme_link: [ nil, "" ])
                                               .where.not(id: ReadmeCertification.unscoped.select(:project_id))
                                               .pluck(:id)

    project_ids_needing_certification.each do |project_id|
      ReadmeCertification.create!(project_id: project_id)
    end

    Rails.logger.info "Created #{project_ids_needing_certification.count} README certifications"
  end
end
