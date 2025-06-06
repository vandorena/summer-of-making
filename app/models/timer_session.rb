# == Schema Information
#
# Table name: timer_sessions
#
#  id                 :bigint           not null, primary key
#  accumulated_paused :integer          default(0), not null
#  last_paused_at     :datetime
#  net_time           :integer          default(0), not null
#  started_at         :datetime         not null
#  status             :integer          default("running"), not null
#  stopped_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  devlog_id          :bigint
#  project_id         :bigint           not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_timer_sessions_on_devlog_id   (devlog_id)
#  index_timer_sessions_on_project_id  (project_id)
#  index_timer_sessions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (devlog_id => devlogs.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class TimerSession < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :devlog, foreign_key: "devlog_id", optional: true

  enum :status, { running: 0, paused: 1, stopped: 2 }

  validates :user, :project, :started_at, :status, presence: true
  validate :validate_no_changes_if_stopped, on: :update
  validate :validate_minimum_duration, on: :update

  before_destroy :prevent_destroy_if_stopped

  MINIMUM_DURATION = 300 # 5 minutes

  private

  def validate_no_changes_if_stopped
    if status_was == "stopped" && changed? && (changed - [ "devlog_id" ]).present?
      errors.add(:base, "Stopped timer sessions cannot be modified")
    end
  end

  def validate_minimum_duration
    if status_changed? && status == "stopped" && net_time < MINIMUM_DURATION
      errors.add(:base, "Timer sessions must be at least 5 minutes long")
    end
  end

  def prevent_destroy_if_stopped
    if stopped?
      errors.add(:base, "Stopped timer sessions cannot be deleted")
      throw :abort
    end
  end
end
