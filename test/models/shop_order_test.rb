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
require "test_helper"

class ShopOrderTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @free_stickers = ShopItem::FreeStickers.create!(
      name: "Free Stickers",
      description: "Free stickers for everyone",
      ticket_cost: 0
    )
  end

  test "free sticker orders start in verification limbo when user has no identity vault" do
    # Set user as not linked to identity vault
    @user.update!(identity_vault_id: nil)
    order = @user.shop_orders.build(shop_item: @free_stickers, quantity: 1)
    order.save!
    assert_equal "in_verification_limbo", order.aasm_state
  end

  test "free sticker orders start as awaiting_periodical_fulfillment when user has identity vault" do
    # Set user as linked to identity vault
    @user.update!(identity_vault_id: "some-id")
    order = @user.shop_orders.build(shop_item: @free_stickers, quantity: 1)
    order.save!
    assert_equal "awaiting_periodical_fulfillment", order.aasm_state
    assert_not_nil order.awaiting_periodical_fulfillment_at
  end

  test "non-free sticker orders always start as pending" do
    regular_item = ShopItem.create!(
      name: "Regular Item",
      description: "Not free stickers",
      ticket_cost: 100
    )

    @user.update!(ysws_verified: false)
    order = @user.shop_orders.build(shop_item: regular_item, quantity: 1)
    order.save!
    assert_equal "pending", order.aasm_state
  end
end
