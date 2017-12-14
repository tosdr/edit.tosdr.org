# in repo root, run:
# rails runner db/import_topics_from_old_db.rb

filepath_topics = "old_db/topics/"

def importTopic(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  imported_topic = Topic.new(
    title: data['title'],
    subtitle: data['subtitle'],
    description: data['description']
  )
  puts imported_topic
  imported_topic.save
  puts 'saved.'
end

puts "Importing topics..."
Dir.foreach(filepath_topics) do |filename|
  next if filename == '.' or filename == '..' or filename == 'README.md'
  file = File.read(filepath_topics + filename)
  data = JSON.parse(file)
  importTopic(data)
end
puts "Finishing importing topics"
puts "Done!"
