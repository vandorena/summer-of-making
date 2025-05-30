class CreateShopItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_items do |t|
      t.string :type
      t.string :name
      t.string :description
      t.string :internal_description
      t.decimal :actual_irl_fr_cost, precision: 6, scale: 2
      t.decimal :cost, precision: 6, scale: 2
      t.string :hacker_score, precision: 1, scale: 2
      t.boolean :requires_black_market
      t.string :hcb_merchant_lock
      t.string :hcb_category_lock
      t.string :hcb_keyword_lock
      t.jsonb :agh_contents

      t.timestamps
    end
  end
end
