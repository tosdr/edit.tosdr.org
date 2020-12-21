namespace :service do
  desc "Calculate the ratings for each service and store in db"
  task perform_rating: :environment do
    services = Service.all
    services.each do |service|
      initial_rating = service.rating
      new_rating = service.calculate_service_rating
      if initial_rating != new_rating
        service.rating = new_rating
        service.save(validate: false)

        version = Version.new
        version.item_type = "Service"
        version.item_id = service.id
        version.event = "update"
        version.whodunnit = "21311"
        version.object_changes = "This has been an automatic update by an official ToS;DR bot. The rating for this service changed from #{initial_rating} to #{new_rating}."
        version.save
      end
    end
  end
end
