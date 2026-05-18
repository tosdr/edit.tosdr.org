# frozen_string_literal: true

Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.data_source_exists?('users')
  next unless ActiveRecord::Base.connection.column_exists?(:users, :level)

  User.backfill_missing_levels!
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  nil
end
