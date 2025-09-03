require "test_helper"

class ShipReviewerAutopayJobTest < ActiveJob::TestCase
  def setup
    @reviewer = users(:admin)
    @project = projects(:one)
  end

  test "should pay reviewer 0.5 shells for every 2 decisions" do
    # Create 4 ship certifications with decisions
    4.times do |i|
      cert = ShipCertification.create!(
        project: @project,
        reviewer: @reviewer,
        judgement: i.even? ? :approved : :rejected
      )
    end

    assert_difference -> { Payout.count }, 1 do
      ShipReviewerAutopayJob.perform_now(@reviewer.id)
    end

    payout = Payout.last
    assert_equal @reviewer, payout.user
    assert_equal 1.0, payout.amount # 2 cycles of 0.5 shells = 1.0 shell
    assert_match /Ship certification review payment: 4 decisions/, payout.reason
  end

  test "should not pay for less than 2 decisions" do
    # Create only 1 decision
    ShipCertification.create!(
      project: @project,
      reviewer: @reviewer,
      judgement: :approved
    )

    assert_no_difference -> { Payout.count } do
      ShipReviewerAutopayJob.perform_now(@reviewer.id)
    end
  end

  test "should not double-pay for already paid decisions" do
    # Create 4 decisions
    4.times do |i|
      ShipCertification.create!(
        project: @project,
        reviewer: @reviewer,
        judgement: i.even? ? :approved : :rejected
      )
    end

    # First payment
    ShipReviewerAutopayJob.perform_now(@reviewer.id)
    first_payout_count = Payout.count

    # Second call should not create additional payment
    assert_no_difference -> { Payout.count } do
      ShipReviewerAutopayJob.perform_now(@reviewer.id)
    end
  end

  test "should handle reviewer not found gracefully" do
    assert_nothing_raised do
      ShipReviewerAutopayJob.perform_now(99999)
    end

    assert_no_difference -> { Payout.count } do
      ShipReviewerAutopayJob.perform_now(99999)
    end
  end

  test "should only count actual decisions not pending certifications" do
    # Create 2 pending certifications (should not count)
    2.times do
      ShipCertification.create!(
        project: @project,
        reviewer: @reviewer,
        judgement: :pending
      )
    end

    # Create 2 actual decisions
    2.times do |i|
      ShipCertification.create!(
        project: @project,
        reviewer: @reviewer,
        judgement: i.even? ? :approved : :rejected
      )
    end

    assert_difference -> { Payout.count }, 1 do
      ShipReviewerAutopayJob.perform_now(@reviewer.id)
    end

    payout = Payout.last
    assert_equal 0.5, payout.amount # Only 1 cycle of payment for 2 actual decisions
    assert_match /Ship certification review payment: 2 decisions/, payout.reason
  end
end