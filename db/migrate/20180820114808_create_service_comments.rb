class CreateServiceComments < ActiveRecord::Migration[5.1]
  def change
    create_table :service_comments do |t|
      t.string :summary
      t.references :service, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
