# frozen_string_literal: true

# In-process scheduler using rufus-scheduler.
# Replaces system cron (which doesn't work reliably in Docker).
# All times are UTC.

require 'rufus-scheduler'

return unless defined?(Puma) || defined?(Rails::Server) || ENV['RUN_SCHEDULER'] == 'true'

Rails.application.load_tasks

scheduler = Rufus::Scheduler.singleton

Rails.logger.info('[Scheduler] Initializing scheduled tasks...')

# service:perform_rating — Mon, Wed, Fri at 3:00 AM
scheduler.cron '0 3 * * 1,3,5' do
  Rails.logger.info('[Scheduler] Running service:perform_rating')
  Rake::Task['service:perform_rating'].reenable
  Rake::Task['service:perform_rating'].invoke
end

# spam:clean_spam — Tue, Thu at 3:00 AM
scheduler.cron '0 3 * * 2,4' do
  Rails.logger.info('[Scheduler] Running spam:clean_spam')
  Rake::Task['spam:clean_spam'].reenable
  Rake::Task['spam:clean_spam'].invoke
end

# bounced_emails:fetch — Daily at 4:00 AM
scheduler.cron '0 4 * * *' do
  Rails.logger.info('[Scheduler] Running bounced_emails:fetch')
  Rake::Task['bounced_emails:fetch'].reenable
  Rake::Task['bounced_emails:fetch'].invoke
end

Rails.logger.info('[Scheduler] 3 tasks scheduled.')
