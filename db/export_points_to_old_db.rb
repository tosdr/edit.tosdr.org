# in repo root, run:
# rails runner db/export_points_to_old_db.rb

require 'json'

filepath_points = "old_db/points/"
counter = Date.today.to_time.to_i * 1000

puts "Exporting points..."
Point.all.each do |point|
  puts point.to_json
  puts point.service.to_json
  if (point.oldId.nil?) then 
    puts 'yes!'
    puts counter
    puts point.to_json
    point.oldId = counter
    counter = counter + 1
    filename = point.oldId + '.json'
    data = {}
    data['tosdr'] = {}
  else
    filename = point.oldId + '.json'
    file = File.read(filepath_points + filename)
    data = JSON.parse(file)
  end
  puts data
  data['id'] = point.oldId
  data['title'] = point.title
  data['tosdr']['tldr'] = point.analysis
  # data['tosdr']['tmp_rating'] = point.rating
  if (data['services'].nil?) then
    data['services'] = [ point.service.slug ]
  end
  File.write(filepath_points + filename, JSON.pretty_unparse(data))
end
puts "Finishing exporting points"
puts "Done!"
