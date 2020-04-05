namespace :service do
  desc "Calculate the ratings for each service and store in db"
  task perform_rating: :environment do
    services = Service.all
    services.each do |service|
      service.rating = service.calculate_service_rating
      service.save(validate: false)
    end
  end
end
