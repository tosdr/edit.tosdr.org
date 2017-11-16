require 'json'

# make the code take the different file in the folder
filepath = "../old_db/"

puts "Importing topics..."
File.readlines('filename').each do |line|
  imported_topic = Topic.new(
    title: ,
    subtitle: ,
    description: ,)
  imported_topic.save
end
puts "Finishing importing topics!"


puts "Importing services..."
File.readlines('filename').each do |line|
  imported_service = Service.new(
    name: ,
    url: ,
    grade: ,)
  imported_service.save
end
puts "Finishing importing service"

File.readlines('filename').each do |line|
  Point.new(
    user_id: # go make the script look for the user, if no user, make it default
    title: line.title,
    source: line.discussion,
    status: "pending" unless line.needModeration == "true",
    analysis:  #find the JSON value,
    rating: line.tosdr.score, #check if this is working
    service_id: , #need to import the services first and match it by string
    topic_id: ,  #need to import topics first and match it by string
    )
end
