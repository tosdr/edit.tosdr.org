Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5000'
    resource '/api/v1/points', headers: :any, methods: [:post]
  end
end