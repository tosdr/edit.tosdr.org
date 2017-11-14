class AddingGradeToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :grade, :string
  end
end
