class TimerSession < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :update_record, class_name: "Update", foreign_key: "update_id", optional: true

  enum :status, { running: 0, paused: 1, stopped: 2 }

  validates :user, :project, :started_at, :status, presence: true
end
