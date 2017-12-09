require 'json'
require 'pry'

puts "Starting the loop and the import..."
Dir[File.join(Rails.root,"old_db/services/*.json")].each do |json_file|
  hash = JSON.parse(File.read(json_file))
  imported_service = Service.new(
    name: hash['name'],
    url: hash['fulltos']['terms']['url']
    )
  imported_service.save
  byebug
  unless imported_service.valid?
    puts "### #{imported_service.name} not imported ! ###"
  else
    puts "Imported and saved: #{imported_service.name}"
  end
  puts "Exiting loop"
end
puts "Finishing importing topics!"
