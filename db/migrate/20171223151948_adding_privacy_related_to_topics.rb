class AddingPrivacyRelatedToTopics < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :privacy_related, :boolean
  end
end
