class BouncedEmail < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  PERMANENTLY_BLOCKED = %w[deactivated_account@tosdr.org].freeze

  def self.bounced?(email)
    return true if PERMANENTLY_BLOCKED.include?(email.downcase)

    where('lower(email) = ?', email.downcase).exists?
  end
end
