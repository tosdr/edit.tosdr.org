require 'json'
require 'pry'

# in repo root, run
# rails runner db/import_points_from_old_db.rb

filepath_points = "old_db/points/"

puts "Importing points..."
Dir.foreach(filepath_points) do |filename|
  next if filename == '.' or filename == '..'
  file = File.read(filepath_points + filename)
  data = JSON.parse(file)
  puts data
  imported_point = Point.new(
#   user_id: # go make the script look for the user, if no user, make it default
    title: data['title'],
    source: data['discussion'],
    status: (data['needModeration'] == "false" ? "approved" : "pending"),
    analysis: data['tldr'],
    rating: data['tosdr']['score']
#    service = Service.find_by_name(line['services'])
#    binding.pry
#    service_id: service.id,
#    topic = Topic.find_by_title(line['topics']) #need to import the services first and match it by string
#    topic_id: topic.id, #need to import topics first and match it by string
    )
  imported_point.save
end
puts "Finishing importing points"
puts "Done!"
