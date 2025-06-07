class CreateEmailSignups < ActiveRecord::Migration[8.0]
  def change
    create_table :email_signups do |t|
      t.text :email, null: false

      t.timestamps
    end
  end
end
