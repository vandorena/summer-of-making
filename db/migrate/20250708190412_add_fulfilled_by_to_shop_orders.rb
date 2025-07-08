class AddFulfilledByToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :fulfilled_by, :string
  end
end
