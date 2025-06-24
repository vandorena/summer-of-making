class CreateReadmeCertifications < ActiveRecord::Migration[8.0]
  def change
    create_table :readme_certifications do |t|
      t.belongs_to :reviewer, null: true, foreign_key: { to_table: :users }
      t.belongs_to :project, null: false, foreign_key: true
      t.integer :judgement, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :readme_certifications, [ :project_id, :judgement ]
  end
end
