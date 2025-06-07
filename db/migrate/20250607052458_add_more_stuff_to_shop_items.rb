class AddMoreStuffToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :rejection_reason, :string
    add_column :shop_orders, :external_ref, :string
    add_column :shop_orders, :awaiting_periodical_fulfillment_at, :datetime
    add_column :shop_orders, :fulfilled_at, :datetime
    add_column :shop_orders, :rejected_at, :datetime
    add_column :shop_orders, :on_hold_at, :datetime
  end
end
