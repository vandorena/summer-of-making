class AddOptimizedIndexesToPayouts < ActiveRecord::Migration[8.0]
  def change
    add_index :payouts, :created_at, name: "index_payouts_on_created_at"
    add_index :payouts, [ :created_at, :amount ], name: "index_payouts_on_created_at_and_amount"
    add_index :payouts, :payable_type, name: "index_payouts_on_payable_type"
    add_index :payouts, [ :created_at, :payable_type, :amount ], name: "index_payouts_on_date_type_amount"
  end
end
