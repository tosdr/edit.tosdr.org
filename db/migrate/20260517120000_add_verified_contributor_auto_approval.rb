# frozen_string_literal: true

class AddVerifiedContributorAutoApproval < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :verified_contributor, :boolean, default: false, null: false
    add_column :points, :auto_approve_after, :datetime
    add_index :points, :auto_approve_after
  end
end
