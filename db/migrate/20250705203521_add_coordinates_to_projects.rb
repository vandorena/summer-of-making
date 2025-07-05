class AddCoordinatesToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :x, :float
    add_column :projects, :y, :float
    add_index :projects, [ :x, :y ]
    add_index :projects, :is_shipped
  end
end
