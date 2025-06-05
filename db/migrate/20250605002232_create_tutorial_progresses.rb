class CreateTutorialProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :tutorial_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :step_progress, null: false, default: {}
      t.datetime :completed_at

      t.timestamps
    end
  end
end
