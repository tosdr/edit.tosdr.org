require 'csv'

def rating_get(service)
  service.calculate_service_rating
end

namespace :service do
  desc "Calculate the ratings for each service and store in CSV to be accessed later"
  task perform_rating: :environment do
    services = Service.all
    write_parameters = { write_headers: true, headers: %w(id, rating) }

    CSV.open("new_service_ratings.csv", "w+", write_parameters) do |new_csv|
      services.each do |service|
        rating = rating_get(service)
        new_csv << [service.id.to_s, rating]
      end
    end

    if File.exists?("new_service_ratings.csv")
      FileUtils.cp("new_service_ratings.csv", "service_ratings.csv")
      FileUtils.rm("new_service_ratings.csv")
    end
  end
end
