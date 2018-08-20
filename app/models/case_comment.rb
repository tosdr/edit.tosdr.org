class CaseComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :case
end
