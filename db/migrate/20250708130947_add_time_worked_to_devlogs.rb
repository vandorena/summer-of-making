class AddTimeWorkedToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :time_worked, :integer, default: 0, null: false
  end
end
