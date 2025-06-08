class CreatePayouts < ActiveRecord::Migration[8.0]
  def change
    create_table :payouts do |t|
      t.decimal :amount, precision: 6, scale: 2
      t.references :payable, polymorphic: true, null: true
      t.references :user, null: false

      t.timestamps
    end
  end
end
