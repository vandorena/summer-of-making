class AddHasClickedCompletedTutorialModalToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :has_clicked_completed_tutorial_modal, :boolean
  end
end
