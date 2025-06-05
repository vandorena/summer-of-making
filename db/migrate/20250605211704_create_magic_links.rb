class CreateMagicLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :magic_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false

      t.timestamps
    end
  end
end
