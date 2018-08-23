class DocumentComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :document
end
