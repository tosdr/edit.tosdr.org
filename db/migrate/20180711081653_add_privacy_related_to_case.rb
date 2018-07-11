class AddPrivacyRelatedToCase < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :privacy_related, :boolean
  end
end
