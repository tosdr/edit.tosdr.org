class CaseComment < ApplicationRecord
  include SpamHelpers

  validates :summary, presence: true
  belongs_to :case
  belongs_to :user
  has_many :spams, as: :spammable

  # Add validation
  validate :summary_must_not_contain_external_uris

  private

  def summary_must_not_contain_external_uris
    return unless contains_external_uri?(user, summary)

    errors.add(:summary, 'cannot contain external URIs')
  end
end
