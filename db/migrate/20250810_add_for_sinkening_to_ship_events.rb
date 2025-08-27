class AddForSinkeningToShipEvents < ActiveRecord::Migration[6.0]
  # this is a placeholder migration while fixing the schema.rb so we can rollback and reapply ./20250810000000_add_for_sinkening_to_ship.rb
  def up
    add_column :ship_events, :for_sinkening, :boolean, default: false, null: false
  end

  def down
    # intentionally left blank so we don't make changes on rollback
  end
end
