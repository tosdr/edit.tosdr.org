class AddUserRefToServices < ActiveRecord::Migration[5.1]
  def change
    add_reference :services, :user, foreign_key: true
  end
end
