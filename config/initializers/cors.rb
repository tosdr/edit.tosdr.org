Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5000'
    resource '*', headers: :any, methods: %I[post patch delete get]
  end
end