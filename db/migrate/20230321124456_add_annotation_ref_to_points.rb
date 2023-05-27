class AddAnnotationRefToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :annotation_ref, :string
  end
end
