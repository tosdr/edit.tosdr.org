class AddingPrivacyRelatedToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :privacy_related, :boolean
  end
end
