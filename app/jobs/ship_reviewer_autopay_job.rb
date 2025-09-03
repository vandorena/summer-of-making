class ShipReviewerAutopayJob < ApplicationJob
  queue_as :default

  PAYMENT_PER_TWO_DECISIONS = 0.5

  def perform(reviewer_id)
    reviewer = User.find_by(id: reviewer_id)
    return unless reviewer

    # Count unpaid decisions for this reviewer
    unpaid_decisions = count_unpaid_decisions(reviewer)
    
    # Calculate how many payments of 0.5 shell we should make
    payment_cycles = unpaid_decisions / 2
    
    return if payment_cycles == 0

    # Create payout for completed pairs
    total_amount = payment_cycles * PAYMENT_PER_TWO_DECISIONS
    
    Payout.create!(
      user: reviewer,
      amount: total_amount,
      reason: "Ship certification review payment: #{payment_cycles * 2} decisions",
      payable: reviewer
    )

    Rails.logger.info "Paid #{reviewer.display_name || reviewer.email} #{total_amount} shells for #{payment_cycles * 2} ship certification decisions"
  end

  private

  def count_unpaid_decisions(reviewer)
    # Count all decisions made by this reviewer that haven't been paid yet
    # We'll track this by checking if there's already a payout for recent decisions
    recent_decisions = ShipCertification
      .where(reviewer: reviewer)
      .where.not(judgement: :pending)
      .where('updated_at > created_at') # Only count actual decisions, not initial pending state
      .count

    # Count existing payouts for this reviewer related to ship certifications
    existing_payouts = Payout
      .where(user: reviewer, payable: reviewer)
      .where("reason LIKE ?", "Ship certification review payment:%")
      .sum('CAST(SUBSTRING(reason FROM ''(\d+) decisions'') AS INTEGER)')
      .to_i

    # Return unpaid decisions
    recent_decisions - existing_payouts
  end
end