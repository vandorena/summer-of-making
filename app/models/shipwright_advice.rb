# == Schema Information
#
# Table name: project_improvements
#
#  id                    :bigint           not null, primary key
#  completed_at          :datetime
#  description           :text
#  proof_link            :string
#  shell_reward          :integer          default(0)
#  status                :integer          default("pending")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  project_id            :bigint           not null
#  ship_certification_id :bigint           not null
#
# Indexes
#
#  index_project_improvements_on_project_id             (project_id)
#  index_project_improvements_on_project_id_and_status  (project_id,status)
#  index_project_improvements_on_ship_certification_id  (ship_certification_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (ship_certification_id => ship_certifications.id)
#
class ShipwrightAdvice < ApplicationRecord
  self.table_name = 'project_improvements'
  belongs_to :project
  belongs_to :ship_certification

  enum :status, {
    pending: 0,
    completed: 1,
    rewarded: 2
  }

  validates :description, presence: true
  validates :proof_link, presence: true, if: :completed?
  validates :proof_link, format: { with: /\A(?:https?:\/\/).*\z/i, message: "must be a valid HTTP or HTTPS URL" }, allow_blank: true

  scope :for_user, ->(user) { joins(:project).where(projects: { user: user }) }

  def can_be_completed?
    pending?
  end

  def complete!(proof_link, shell_amount = 10)
    return false unless can_be_completed?

    transaction do
      update!(
        status: :completed,
        proof_link: proof_link,
        completed_at: Time.current,
        shell_reward: shell_amount
      )

      # Create payout for the improvement
      Payout.create!(
        user: project.user,
        amount: shell_amount,
        reason: "Improvement completed for '#{project.title}': #{description.truncate(50)}",
        payable: self,
        escrowed: false
      )

      update!(status: :rewarded)
    end

    true
  rescue => e
    errors.add(:base, e.message)
    false
  end
end
