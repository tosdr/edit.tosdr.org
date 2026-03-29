class CreateBouncedEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :bounced_emails do |t|
      t.string :email, null: false
      t.string :bounce_type
      t.datetime :bounced_at
      t.timestamps
    end

    add_index :bounced_emails, :email, unique: true
  end
end
