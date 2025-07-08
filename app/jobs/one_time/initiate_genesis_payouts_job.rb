class OneTime::InitiateGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Payout.where(payable_type: "ShipEvent").any? # Protect from running twice

    Project.find_each { |p| p.issue_payouts(all_time: true) }
  end
end
