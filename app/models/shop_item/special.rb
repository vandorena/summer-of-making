# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_items
#
#  id                    :bigint           not null, primary key
#  actual_irl_fr_cost    :decimal(6, 2)
#  agh_contents          :jsonb
#  cost                  :decimal(6, 2)
#  description           :string
#  hacker_score          :string
#  hcb_category_lock     :string
#  hcb_keyword_lock      :string
#  hcb_merchant_lock     :string
#  internal_description  :string
#  name                  :string
#  requires_black_market :boolean
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class ShopItem::Special < ShopItem
end
