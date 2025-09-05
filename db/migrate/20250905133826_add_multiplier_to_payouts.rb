class AddMultiplierToPayouts < ActiveRecord::Migration[8.0]
  def change
    add_column :payouts, :multiplier, :decimal
  end
end
