class DocumentComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :document
  belongs_to :user
  has_many :spams, as: :spammable
end
