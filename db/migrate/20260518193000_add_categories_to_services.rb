# frozen_string_literal: true

class AddCategoriesToServices < ActiveRecord::Migration[7.1]
  CATEGORIES = %w[
    ai
    browser
    cloud_storage
    dating
    developer_tools
    ecommerce
    education
    email
    entertainment
    file_sharing
    finance
    gaming
    health
    messaging
    news
    payments
    productivity
    search_engine
    social_network
    travel
    vpn
  ].freeze

  def up
    create_enum :service_category, CATEGORIES
    add_column :services, :categories, :service_category, array: true, default: [], null: false
  end

  def down
    remove_column :services, :categories
    drop_enum :service_category
  end
end
