# frozen_string_literal: true

class AddUserLevelsAndPointVetoes < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :approved_points_count, :integer, default: 0, null: false
    add_column :users, :level, :integer, default: 1, null: false
    add_index :users, :level

    create_table :point_vetoes do |t|
      t.references :point, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :point_vetoes, %i[point_id user_id], unique: true

    execute <<~SQL.squish
      UPDATE users
      SET approved_points_count = approved_counts.approved_count,
          level = FLOOR(SQRT(approved_counts.approved_count)) + 1
      FROM (
        SELECT users.id, COUNT(points.id) AS approved_count
        FROM users
        LEFT JOIN points ON points.user_id = users.id AND points.status = 'approved'
        GROUP BY users.id
      ) approved_counts
      WHERE users.id = approved_counts.id
    SQL
  end

  def down
    drop_table :point_vetoes
    remove_index :users, :level
    remove_column :users, :level
    remove_column :users, :approved_points_count
  end
end
