require 'json'
require 'pry'

# in repo root, run:
# rails runner db/import_points_from_old_db.rb

filepath_points = "old_db/points/"

def importPoint(data, service)
  puts 'old data:'
  puts data
  puts service
  puts 'new data:'
  imported_point = Point.new(
    id: data['id'] + '-' + service,
    title: data['title']
    # service: service # todo: tell rails that this is a foreign key
  )
  puts imported_point
#    service = Service.find_by_name(line['services'])
#    binding.pry
#    service_id: service.id,
#    topic = Topic.find_by_title(line['topics']) #need to import the services first and match it by string
#    topic_id: topic.id, #need to import topics first and match it by string
  imported_point.save
  puts 'saved.'
end

puts "Importing points..."
Dir.foreach(filepath_points) do |filename|
  next if filename == '.' or filename == '..' or filename == 'README.md'
  file = File.read(filepath_points + filename)
  data = JSON.parse(file)
  for i in 0 ... data['services'].size
    importPoint(data, data['services'][i])
  end
end
puts "Finishing importing points"
puts "Done!"
