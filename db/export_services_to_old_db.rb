# in repo root, run:
# rails runner db/export_services_to_old_db.rb

require 'json'

filepath_services = "../tosdr-build/src/services/"

puts "Exporting services..."
Service.all.each do |service|
  puts service.to_json
  filename = service.slug + '.json'
  File.write(filepath_services + filename, JSON.pretty_unparse({
    id: service.slug,
    name: service.name,
    keywords: service.keywords.split(','),
    related: service.related.split(','),
    urls: [ service.url ],
    tosdr: {
      rated: service.grade
    },
    meta: {
      'spec-version': '1.1'
    }
  }))
end
puts "Finishing exporting services"
puts "Done!"
