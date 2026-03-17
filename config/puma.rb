# config/puma.rb

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }.to_i
threads min_threads_count, max_threads_count

worker_count = ENV.fetch("WEB_CONCURRENCY", 0).to_i
workers worker_count if worker_count.positive?

# Keep preload_app! if you’re using any job runners
preload_app!

port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

plugin :tmp_restart

if worker_count.positive?
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end

  before_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end
