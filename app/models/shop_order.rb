# == Schema Information
#
# Table name: shop_orders
#
#  id                :bigint           not null, primary key
#  aasm_state        :string
#  frozen_address    :jsonb
#  frozen_item_price :decimal(6, 2)
#  quantity          :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  shop_item_id      :bigint           not null
#  user_id           :bigint           not null
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
  belongs_to :user
  belongs_to :shop_item


end
