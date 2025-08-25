class CreateProjectImprovements < ActiveRecord::Migration[8.0]
  def change
    create_table :project_improvements do |t|
      t.references :project, null: false, foreign_key: true
      t.references :ship_certification, null: false, foreign_key: true
      t.text :description
      t.string :proof_link
      t.integer :status
      t.integer :shell_reward
      t.datetime :completed_at

      t.timestamps
    end
  end
end
