require 'rails_helper'

RSpec.describe BounceInterceptor do
  describe '.delivering_email' do
    it 'does not log raw bounced recipient addresses when blocking delivery' do
      message = Mail::Message.new(to: 'bounced@example.test')
      allow(BouncedEmail).to receive(:bounced?).with('bounced@example.test').and_return(true)

      expect(Rails.logger).to receive(:info).with(satisfy { |message| !message.include?('bounced@example.test') })

      described_class.delivering_email(message)

      expect(message.perform_deliveries).to eq(false)
    end

    it 'does not log raw bounced recipient addresses when filtering recipients' do
      message = Mail::Message.new(to: ['ok@example.test', 'bounced@example.test'])
      allow(BouncedEmail).to receive(:bounced?).with('ok@example.test').and_return(false)
      allow(BouncedEmail).to receive(:bounced?).with('bounced@example.test').and_return(true)

      expect(Rails.logger).to receive(:info).with(satisfy { |message| !message.include?('bounced@example.test') })

      described_class.delivering_email(message)

      expect(message.to).to eq(['ok@example.test'])
    end
  end
end
