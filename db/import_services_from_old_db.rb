# in repo root, run:
# rails runner db/import_services_from_old_db.rb

filepath_services = "old_db/services/"

def importService(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  imported_service = Service.new(
    # old_id: data['id'],
    name: data['name'],
    url: data['urls'][0],
    grade: 'grade'
  )
  puts imported_service
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
