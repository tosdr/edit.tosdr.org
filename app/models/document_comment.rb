class DocumentComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :document
  has_many :spams, as: :spammable
end
