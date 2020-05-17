class CaseComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :case
  has_many :spams, as: :spammable
end
