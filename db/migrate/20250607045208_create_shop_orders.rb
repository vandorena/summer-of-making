class CreateShopOrders < ActiveRecord::Migration[8.0]
  def change
    drop_table :shop_orders, if_exists: true

    create_table :shop_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop_item, null: false, foreign_key: true
      t.decimal :frozen_item_price, precision: 6, scale: 2
      t.integer :quantity
      t.jsonb :frozen_address
      t.string :aasm_state

      t.timestamps
    end
  end
end
