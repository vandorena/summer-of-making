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
require 'test_helper'

class DailyStonkReportTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
