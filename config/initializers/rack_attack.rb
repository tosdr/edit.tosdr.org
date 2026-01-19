class Rack::Attack
  # Use MemoryStore (suitable for dev/single-process production)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Block Known Exploit Paths ###
  blocklist('block exploit paths') do |req|
    %r{^/(wp-admin|wp-login\.php|admin|\.env|vendor/phpunit|\.well-known/traffic-advice|users/.*/wp-login\.php)}.match?(req.path)
  end

  ### Throttles (IP-based) ###

  # POST to /services
  throttle('services/ip', limit: 20, period: 10.minutes) do |req|
    req.ip if req.post? && req.path == '/services'
  end

  # PATCH/PUT to /points/:id
  throttle('points/ip', limit: 10, period: 1.minute) do |req|
    req.ip if (req.patch? || req.put?) && req.path.match?(%r{^/points/\w+})
  end

  # POST to /documents
  throttle('documents/create', limit: 10, period: 10.minutes) do |req|
    req.ip if req.post? && req.path == '/documents'
  end

  # PATCH/PUT to /documents/:id
  throttle('documents/update', limit: 20, period: 10.minutes) do |req|
    req.ip if (req.patch? || req.put?) && req.path.match?(%r{^/documents/\w+})
  end

  # POST to /documents/:id (high-volume sync/crawl)
  throttle('documents/post/high', limit: 100, period: 10.minutes) do |req|
    req.ip if req.post? && req.path.match?(%r{^/documents/\w+})
  end

  # Login IP throttling
  throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
    req.ip if req.post? && (req.path == '/login' || req.path == '/users/sign_in')
  end

  # Login email throttling
  throttle('logins/email', limit: 5, period: 60.seconds) do |req|
    req.params['email'].presence if req.post? && req.path == '/users/sign_in'
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |_env|
    [
      503,
      { 'Retry-After' => '60' },
      ["You're doing too much too fast. Please wait a moment and try again."]
    ]
  end

  ### Optional Logging (disable in prod if noisy) ###
  ActiveSupport::Notifications.subscribe('rack.attack') do |_, _, _, _, payload|
    req = payload[:request]
    Rails.logger.info "[rack-attack] Throttled request to #{req.path} from #{req.ip}"
  end
end