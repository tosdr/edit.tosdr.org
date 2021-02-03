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
  
  
  desc "Mark as reviewed if approved points are over 20"
  task mark_as_reviewed: :environment do
    services = Service.all
	puts "Getting unreviewed services"
    services.where('is_comprehensively_reviewed = false').each do |service|
		approvedPoints = service.points.where("status = 'approved'");
		if approvedPoints.length >= 20 		
			puts "Found #{service.name} - #{service.id}"
			service.is_comprehensively_reviewed = true
			service.save(validate: false)
			puts "Saved Service"
			version = Version.new
			version.item_type = "Service"
			version.item_id = service.id
			version.event = "update"
			version.whodunnit = "21311"
			version.object_changes = "This has been an automatic update by an official ToS;DR bot. The service has been marked as comprehensively reviewed due to a threshold of 20 approved points"
			version.save
		end
    end
  end
end