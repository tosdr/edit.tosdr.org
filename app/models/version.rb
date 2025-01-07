# frozen_string_literal: true

# app/models/version.rb
class Version < ApplicationRecord
  belongs_to :item, polymorphic: true

  def self.with_whodunnit_users
    versions = all.order('created_at DESC').limit(50)
    user_ids = versions.pluck(:whodunnit).compact.uniq.map(&:to_i)
    users = User.where(id: user_ids).index_by(&:id)
    # items = versions.map(&:item).compact.index_by(&:id)

    # Group versions by item_type
    grouped_versions = versions.group_by(&:item_type)

    # Eager load items for each type
    items_by_type = {}
    grouped_versions.each do |item_type, grouped|
      item_ids = grouped.map(&:item_id).compact
      items_by_type[item_type] = item_type.constantize.where(id: item_ids).index_by(&:id)
    end

    # Map versions with their associated items
    versions_with_items = versions.map do |version|
      item = items_by_type[version.item_type][version.item_id] if version.item_type && version.item_id
      {
        version: version,
        item: item
      }
    end

    versions_with_items.map do |data|
      version = data[:version]
      item = data[:item]
      Version::VersionDecorator.new(version, users[version.whodunnit.to_i], item: item)
    end
  end
end
