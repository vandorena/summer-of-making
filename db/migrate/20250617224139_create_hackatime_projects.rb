class CreateHackatimeProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :hackatime_projects do |t|
      t.string :name
      t.integer :seconds
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
