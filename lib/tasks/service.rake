namespace :service do
  desc "Recalculate ratings for all services (in batches)"
  task perform_rating: :environment do
    heartbeat_url = ENV["GRADING_SUCCESS_HEARTBEAT"]

    begin
      batch_size = (ENV["BATCH_SIZE"] || 100).to_i
      debug_mode = ActiveModel::Type::Boolean.new.cast(ENV["DEBUG_RATING"])
      processed_count = 0
      updated_count = 0

      puts "[service:perform_rating] Starting (batch_size=#{batch_size}, debug=#{debug_mode})"

      Service.find_in_batches(batch_size: batch_size) do |services|
        services.each do |service|
          updated = recalculate_service_rating(service, debug_mode)
          processed_count += 1
          updated_count += 1 if updated
        end
      end

      puts "[service:perform_rating] Done (processed=#{processed_count}, updated=#{updated_count})"

      if heartbeat_url.present?
        if system("curl", "-fsS", "-m", "10", heartbeat_url)
          puts "[service:perform_rating] Sent success heartbeat"
        else
          warn "[service:perform_rating] Failed to send success heartbeat"
        end
      end
    
    
    rescue => e
      warn "[service:perform_rating] Failed with error: #{e.message}"
      if heartbeat_url.present?
        url = heartbeat_url.chomp('/') + '/fail'
        if system("curl", "-fsS", "-m", "10", "-d", e.message, url)
          puts "[service:perform_rating] Sent error heartbeat"
        else
          warn "[service:perform_rating] Failed to send error heartbeat"
        end
      end
      return


    end
    
  end

  def recalculate_service_rating(service, debug_mode = false)
    initial_rating = service.rating
    new_rating = service.calculate_service_rating

    if new_rating == initial_rating
      puts "[service:perform_rating] Service ##{service.id} unchanged (rating=#{initial_rating})" if debug_mode
      return false
    end

    service.update_columns(rating: new_rating, updated_at: Time.current)
    puts "[service:perform_rating] Service ##{service.id} updated #{initial_rating} -> #{new_rating}" if debug_mode

    Version.create!(
      item_type: "Service",
      item_id: service.id,
      event: "update",
      whodunnit: "21311",
      object_changes: "This has been an automatic update by an official ToS;DR bot. The rating for this service changed from #{initial_rating} to #{new_rating}."
    )

    true
  end
  
  desc "Mark as reviewed if approved points are over 20"
  task mark_as_reviewed: :environment do
    services = Service.all
	  puts "Getting unreviewed services"
    services.where('is_comprehensively_reviewed = false').each do |service|
		  approved_points = service.approved_points
		  if approved_points.length >= 20 		
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
  
  desc "Create a slug for a service"
  task create_slug: :environment do
    services = Service.all
    puts "Getting services without a slug"
    services.where('slug is null OR slug = \'\'').each do |service|
		  service.slug = ActiveSupport::Inflector.transliterate(service.name).parameterize.downcase
      if service.slug.empty?
        puts "Failed to transliterate #{service.name}. Reverting slug to ID"
        service.slug = service.id
      end
      if service.save(validate: false)
        puts "Created slug for #{service.id}: #{service.slug}"
        version = Version.new
        version.item_type = "Service"
        version.item_id = service.id
        version.event = "update"
        version.whodunnit = "21311"
        version.object_changes = "A slug for the service has been generated: #{service.slug}"
        version.save
      end
    end
  end
end