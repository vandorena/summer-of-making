class RenameCostToTicketCost < ActiveRecord::Migration[8.0]
  def change
    rename_column :shop_items, :cost, :ticket_cost
  end
end
