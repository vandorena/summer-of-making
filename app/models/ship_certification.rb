# == Schema Information
#
# Table name: ship_certifications
#
#  id         :bigint           not null, primary key
#  judgement  :integer          default("pending"), not null
#  notes      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_ship_certifications_on_project_id                (project_id)
#  index_ship_certifications_on_project_id_and_judgement  (project_id,judgement)
#  index_ship_certifications_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class ShipCertification < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_one_attached :proof_video, dependent: :destroy

  enum :judgement, {
    pending: 0,
    approved: 1,
    rejected: 2
  }
end
