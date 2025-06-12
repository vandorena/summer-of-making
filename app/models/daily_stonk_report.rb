# frozen_string_literal: true

# == Schema Information
#
# Table name: daily_stonk_reports
#
#  id         :bigint           not null, primary key
#  date       :date             not null
#  report     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_daily_stonk_reports_on_date  (date) UNIQUE
#
class DailyStonkReport < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :report, presence: true

  def self.for(day = Date.current)
    find_by(date: day)
  end
end
