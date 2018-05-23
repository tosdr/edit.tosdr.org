class RemoveGradeFromServices < ActiveRecord::Migration[5.1]
  def change
    remove_column :services, :grade, :string
  end
end
