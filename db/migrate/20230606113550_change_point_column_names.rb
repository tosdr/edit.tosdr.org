class ChangePointColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :points, :quoteText, :quote_text
    rename_column :points, :oldId, :old_id
    rename_column :points, :quoteStart, :quote_start
    rename_column :points, :quoteEnd, :quote_end
  end
end
