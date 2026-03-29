# DEPRECATED: This file was used by the `whenever` gem for system cron.
# Scheduled tasks are now managed by rufus-scheduler in
# config/initializers/scheduler.rb (runs in-process, Docker-friendly).
#
# Schedule overview:
#   Mon, Wed, Fri at 3:00 AM — service:perform_rating
#   Tue, Thu at 3:00 AM      — spam:clean_spam
#   Daily at 4:00 AM          — bounced_emails:fetch
