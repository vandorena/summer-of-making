class AddSoftTutorialStepsToTutorialProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorial_progresses, :soft_tutorial_steps, :jsonb, null: false, default: {}
  end
end
