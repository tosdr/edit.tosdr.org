# frozen_string_literal: true

class PointVeto < ApplicationRecord
  self.table_name = 'point_vetoes'

  belongs_to :point
  belongs_to :user

  validates :user_id, uniqueness: { scope: :point_id }
end
