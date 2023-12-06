class CaseComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :case
  belongs_to :user
  has_many :spams, as: :spammable
end
