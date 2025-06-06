class DropTextFromComments < ActiveRecord::Migration[8.0]
  def change
    remove_column :comments, :text, :text
  end
end
