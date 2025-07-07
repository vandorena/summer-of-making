class AddFulfillmentCostToShopOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :fulfillment_cost, :decimal, precision: 6, scale: 2, default: 0.0
  end
end
