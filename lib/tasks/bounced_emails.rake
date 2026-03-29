# frozen_string_literal: true

namespace :bounced_emails do
  desc 'Fetch bounced emails from Mailtrap and store them'
  task fetch: :environment do
    account_id = ENV['MAILTRAP_ACCOUNT_ID']
    api_token = ENV['SMTP_PASSWORD']

    if account_id.blank?
      puts 'MAILTRAP_ACCOUNT_ID not set, skipping bounce fetch.'
      next
    end

    if api_token.blank?
      puts 'SMTP_PASSWORD not set, skipping bounce fetch.'
      next
    end

    url = "https://mailtrap.io/api/accounts/#{account_id}/email_logs"
    params = {
      'filters[events][operator]' => 'include_event',
      'filters[events][value][]' => %w[bounce soft_bounce]
    }

    response = HTTParty.get(url, query: params, headers: { 'Api-Token' => api_token })

    unless response.success?
      puts "Failed to fetch bounced emails: #{response.code} #{response.message}"
      next
    end

    messages = response.parsed_response['messages'] || []
    count = 0

    messages.each do |msg|
      email = msg['to']&.downcase
      next if email.blank?

      bounced = BouncedEmail.find_or_initialize_by(email: email)
      bounced.bounce_type ||= 'bounce'
      bounced.bounced_at ||= msg['sent_at']
      if bounced.new_record?
        bounced.save!
        count += 1
      end
    end

    puts "Fetched #{messages.size} bounced messages, added #{count} new bounced emails."
  end
end
