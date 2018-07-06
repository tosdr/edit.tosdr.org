# in repo root, run:
# rails runner db/export_to_site.rb

require 'json'

filepath_api = "../tosdr-build/dist/api/1/service/"

puts "Exporting points..."
Service.all.each do |service|
  serviceData = {}
#  service.points.each do |point|
#    pointData = {}
#    pointData['tosdr'] = {}
#    pointData['id'] = point.id.to_s
#    pointData['title'] = point.title
#    pointData['tosdr']['tldr'] = point.analysis
#    pointData['services'] = [ point.service.slug ]
#    service_data.pointsData.push(pointData) 
#  end
  puts "Writing " + filepath_api + service.slug + '.json'
  File.write(filepath_api + service.slug + '.json', JSON.pretty_unparse(serviceData))
end
puts "Finishing exporting to site"
puts "Done!"
