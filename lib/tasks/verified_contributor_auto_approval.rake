# frozen_string_literal: true

namespace :points do
  desc 'Auto-approve verified contributor points after their 7 day veto period'
  task auto_approve_verified_contributors: :environment do
    Point.auto_approve_veto_expired
  end
end
