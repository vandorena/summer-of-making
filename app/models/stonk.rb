class Stonk < ApplicationRecord
  DEFAULT_AMOUNT = 3 # Fixed amount of 3 dollars per stonk, but it'll be different for dreamland :smiling_face_with_3_hearts:

  belongs_to :user
  belongs_to :project

  validates :amount, presence: true, numericality: { equal_to: DEFAULT_AMOUNT }

  before_validation :set_default_amount, on: :create

  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :recent, -> { where(created_at: 24.hours.ago..Time.current) }
  scope :days_ago, ->(n) { where(created_at: (n+1).days.ago..n.days.ago) }

  private

  def set_default_amount
    self.amount ||= DEFAULT_AMOUNT
  end
end
