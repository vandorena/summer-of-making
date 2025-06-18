class AddSecondsCodedToDevlog < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :seconds_coded, :integer
  end
end
