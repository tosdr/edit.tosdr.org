class AddIsComprehensivelyReviewedToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :is_comprehensively_reviewed, :boolean, :null => false, :default => false
  end
end
