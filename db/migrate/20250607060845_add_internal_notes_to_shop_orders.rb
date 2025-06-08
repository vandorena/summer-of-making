class AddInternalNotesToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :internal_notes, :text
  end
end
