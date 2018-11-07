class RemovePrivacyRelatedFromTopics < ActiveRecord::Migration[5.1]
  def change
    remove_column :topics, :privacy_related, :boolean
  end
end
