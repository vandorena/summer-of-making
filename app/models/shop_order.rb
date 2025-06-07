# == Schema Information
#
# Table name: shop_orders
#
#  id                                 :bigint           not null, primary key
#  aasm_state                         :string
#  awaiting_periodical_fulfillment_at :datetime
#  external_ref                       :string
#  frozen_address                     :jsonb
#  frozen_item_price                  :decimal(6, 2)
#  fulfilled_at                       :datetime
#  internal_notes                     :text
#  on_hold_at                         :datetime
#  quantity                           :integer
#  rejected_at                        :datetime
#  rejection_reason                   :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  shop_item_id                       :bigint           not null
#  user_id                            :bigint           not null
#
# Indexes
#
#  index_shop_orders_on_shop_item_id  (shop_item_id)
#  index_shop_orders_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (user_id => users.id)
#
class ShopOrder < ApplicationRecord
  include AASM
  include PublicActivity::Model
  tracked only: [:create], owner: Proc.new{ |controller, model| controller&.current_user }

  belongs_to :user
  belongs_to :shop_item

  def full_name
    "#{user.first_name} #{user.last_name}'s order for #{quantity} #{shop_item.name.pluralize(quantity)}"
  end

  aasm timestamps: true do # SAGA PATTERN TIME BABEY
                                              # NORMAL STATES: steps we'd like orders to take on their journeys

    state :pending, initial: true             # submitted, awaiting shoperations rubber-stampage
    state :awaiting_periodical_fulfillment    # waiting for one of:
                                              # - shop ops to order something from amazon or smth
                                              # - nightly warehouse coalesce job
                                              # - next minuteman run
                                              # - other "approved but waiting state"
    state :fulfilled                          # we did it reddit! nora lives another day

                                              # EXCEPTION STATES: sometimes things happen.

    state :rejected                           # shoperations rejected an order
    state :in_verification_limbo              # special case for free stickers
    state :on_hold                            # pending fraud investigation? or for some weird other special cases


    event :queue_for_nightly do
      transitions from: :pending, to: :awaiting_periodical_fulfillment
    end

    event :mark_rejected do
      transitions to: :rejected
      before do |rejection_reason|
        self.rejection_reason = rejection_reason
      end
    end

    event :mark_fulfilled do
      transitions to: :fulfilled
      before do |external_ref=nil|
        self.external_ref = external_ref
      end
    end

    event :place_on_hold do
      transitions to: :on_hold
    end

    event :take_off_hold do
      transitions from: :on_hold, to: :pending
    end

    event :user_was_verified do
      transitions from: :in_verification_limbo, to: :awaiting_periodical_fulfillment
    end

  end
end
