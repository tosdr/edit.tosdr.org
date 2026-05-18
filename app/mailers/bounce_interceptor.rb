# frozen_string_literal: true

class BounceInterceptor
  def self.delivering_email(message)
    return unless defined?(BouncedEmail)

    original_to = Array(message.to)
    filtered_to = original_to.reject { |email| BouncedEmail.bounced?(email) }

    if filtered_to.empty?
      message.perform_deliveries = false
      Rails.logger.info("[BounceInterceptor] Blocked email to #{original_to.size} bounced recipient(s).")
    elsif filtered_to.size < original_to.size
      blocked = original_to - filtered_to
      Rails.logger.info("[BounceInterceptor] Removed #{blocked.size} bounced recipient(s) from email.")
      message.to = filtered_to
    end
  end
end
