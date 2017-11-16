require 'json'
require 'pry'

filepath_services = "../old_db/points/"
filename = JSON.read(filepath_points)

puts "Importing points..."
File.readlines(filename).each do |line|
  imported_point = Point.new(
    user_id: # go make the script look for the user, if no user, make it default
    title: line['title'],
    source: line['discussion'],
    status: (line['needModeration'] == "true" ? "approved" : "pending"),
    analysis: line['tldr']
    rating: line['tosdr']['score'],

    service = Service.find_by_name(line['services'])
    binding.pry
    service_id: service.id,
    topic = Topic.find_by_title(line['topics']) #need to import the services first and match it by string
    topic_id: topic.id, #need to import topics first and match it by string
    )
  imported_point.save
end
puts "Finishing importing points"
puts "Done!"
