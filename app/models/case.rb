class Case < ApplicationRecord
  has_many :points
  belongs_to :topic
end
