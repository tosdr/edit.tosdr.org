class RenameReasonInReasons < ActiveRecord::Migration[5.1]
  def change
    rename_column :reasons, :reason, :content
  end
end
