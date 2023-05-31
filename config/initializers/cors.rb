Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5000'
    resource '/api/v1/points', headers: :any, methods: %I[post patch delete]
    resource '/api/v1/cases', headers: :any, methods: :get
  end
end