require 'json'
require 'pry'

filepath_services = "../old_db/services/"
filename = JSON.read(filepath_services)

puts "Importing services..."
File.readlines(filename).each do |line|
  imported_service = Service.new(
    name: line['name'],
    url: line['fulltos']['url'])
  imported_service.save
end
puts "Finishing importing service"
