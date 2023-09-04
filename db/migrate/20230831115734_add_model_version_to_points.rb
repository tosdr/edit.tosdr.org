class AddModelVersionToPoints < ActiveRecord::Migration[5.2]
  def change
    add_column :points, :model_version, :string
  end
end