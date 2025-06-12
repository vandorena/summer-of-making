class CreateReadmeChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :readme_checks do |t|
      t.string :readme_link
      t.string :content
      t.integer :status, default: 0, null: false
      t.integer :decision
      t.string :reason
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
