class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blacklisting and
  # whitelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  # Throttle POST requests to */services by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:signups/ip:#{req.ip}"

  # FIXME: temporarily loosened this from 2 to 50 due to
  # https://github.com/tosdr/edit.tosdr.org/issues/929#issuecomment-743216243
  throttle('services/ip', limit: 50, period: 10.minutes) do |req|
    if req.path.end_with?('/services') && req.post?
      req.ip
    end
  end

  throttle('points/ip', limit: 5, period: 10.minutes) do |req|
    match = req.path.match(/^\/points\/(\w+)/)
    if (req.patch? || req.put?) &&  !match.nil?
      req.ip
    end
  end

  throttle('throttle document creation', limit: 5, period: 10.minutes) do |req|
    if req.path.end_with?('/documents') && req.post?
      req.ip
    end
  end

  # FIXME: temporarily loosened this from 5 to 50 due to
  # https://github.com/tosdr/edit.tosdr.org/issues/929#issuecomment-743216243
  throttle('throttle document updates', limit: 50, period: 10.minutes) do |req|
    match = req.path.match(/^\/documents\/(\w+)/)
    if (req.patch? || req.put?) &&  !match.nil?
      req.ip
    end
  end

  # FIXME: temporarily loosened this from 5 to 500 due to
  # https://github.com/tosdr/edit.tosdr.org/issues/929#issuecomment-743216243
  throttle('document crawling + creation for specific services', limit: 500, period: 10.minutes) do |req|
    match = req.path.match(/^\/documents\/(\w+)/)
    if req.post? && !match.nil?
      req.ip
    end
  end



  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /login by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
    if req.path == 'users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /login by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{req.email}"
  #
  # Note: This creates a problem where a malicious user could intentionally
  # throttle logins for another user and force their login requests to be
  # denied, but that's not very common and shouldn't happen to you. (Knock
  # on wood!)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == 'users/sign_in' && req.post?
      # return the email if present, nil otherwise
      req.params['email'].presence
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  self.throttled_response = lambda do |env|
   [ 503,  # status
     {},   # headers
     ["Oops! It looks like you're doing many different things in a short period of time. We check for this to prevent abusive requests or other types of vandalism to our site. Please try again in 10 minutes."]] # body
  end
end
