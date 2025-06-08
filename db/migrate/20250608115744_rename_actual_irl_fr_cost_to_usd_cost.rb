class RenameActualIrlFrCostToUsdCost < ActiveRecord::Migration[8.0]
  def change
    rename_column :shop_items, :actual_irl_fr_cost, :usd_cost
  end
end
