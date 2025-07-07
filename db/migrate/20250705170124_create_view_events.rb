class CreateViewEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :view_events do |t|
      t.references :viewable, polymorphic: true, null: false, index: true
      t.bigint :user_id, null: true, index: true
      t.string :ip_address, null: true
      t.string :user_agent, null: true

      t.timestamps
    end

    add_index :view_events, [ :viewable_type, :viewable_id, :created_at ]
    add_index :view_events, :created_at
    add_foreign_key :view_events, :users, column: :user_id
  end
end
