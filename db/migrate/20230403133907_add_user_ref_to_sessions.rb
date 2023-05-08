class AddUserRefToSessions < ActiveRecord::Migration[5.2]
  def change
    add_reference :sessions, :user, foreign_key: true
  end
end