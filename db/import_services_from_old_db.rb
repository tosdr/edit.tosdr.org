# in repo root, run:
# rails runner db/import_services_from_old_db.rb

filepath_services = "old_db/services/"

def importService(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  puts data['name'].downcase
  puts data['urls'][0] || 'url'
  puts data['id']
  puts (data['tosdr']['keywords'] ? data['tosdr']['keywords'].join(',') : '')
  puts (data['tosdr']['related'] ? data['tosdr']['related'].join(',') : '')
  puts data['tosdr']['rated']
  imported_service = Service.new(
    name: data['name'].downcase,
    url: data['urls'][0] || 'url',
    slug: data['id'],
    keywords: (data['keywords'] ? data['keywords'].join(',') : ''),
    related: (data['tosdr']['related'] ? data['tosdr']['related'].join(',') : ''),
    grade: data['tosdr']['rated']
  )
  puts imported_service
  unless imported_service.valid?
    puts "### #{imported_service.name} not imported ! ###" + panic
  end
  imported_service.save
  puts 'saved.'
end

puts "Importing services..."
Dir.foreach(filepath_services) do |filename|
  next if filename == '.' or filename == '..' or filename == 'README.md'
  file = File.read(filepath_services + filename)
  data = JSON.parse(file)
  importService(data)
end
puts "Finishing importing services"
puts "Done!"
