module Admin
  class PayoutsDashboardController < ApplicationController
    before_action :admin_required

    def index
      @cap = Payout.sum(:amount)

      yesterday = 24.hours.ago
      recent = Payout.where(created_at: yesterday..)

      @created = recent.where("amount > 0").sum(:amount)
      @destroyed = recent.where("amount < 0").sum(:amount).abs

      spenders = Payout.joins(:user)
                      .where(created_at: yesterday.., amount: ...0, payable_type: "ShopOrder")
                      .group("users.id", "users.display_name", "users.avatar")
                      .sum("payouts.amount")

      @spenders = spenders.map { |user_data, amount| [ user_data, amount.abs ] }
                         .sort_by { |_, amount| -amount }
                         .first(10)

      balances = {}
      User.joins(:payouts).includes(:payouts).each do |user|
        balance = user.payouts.sum(:amount)
        if balance > 0
          balances[[ user.id, user.display_name, user.avatar ]] = balance
        end
      end

      @holders = balances.sort_by { |_, balance| -balance }.first(10)

      @txns = recent.count
      @volume = recent.sum("ABS(amount)")

      @sources = {}
      recent.group(:payable_type).group("amount > 0").sum(:amount).each do |key, amount|
        @sources[key] = amount
      end

      @creation = {}
      @destruction = {}

      30.times do |i|
        date = i.days.ago.to_date
        created = Payout.where(created_at: date.all_day, amount: 0..).sum(:amount)
        destroyed = Payout.where(created_at: date.all_day, amount: ...0).sum(:amount).abs

        @creation[date] = created
        @destruction[date] = destroyed
      end

      @circulation = {}
      total = Payout.where("created_at < ?", 30.days.ago).sum(:amount)

      30.times do |i|
        date = i.days.ago.to_date
        change = Payout.where(created_at: date.all_day).sum(:amount)
        total += change
        @circulation[date] = total
      end

      @creation = @creation.sort.to_h
      @destruction = @destruction.sort.to_h
      @circulation = @circulation.sort.to_h

      @types = {}
      Payout.where(created_at: 7.days.ago..).group(:payable_type).sum("ABS(amount)").each do |type, volume|
        @types[type&.humanize || "Unknown"] = volume
      end
    end

    private

    def admin_required
      redirect_to root_path unless current_user&.is_admin?
    end
  end
end
