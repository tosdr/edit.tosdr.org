# in repo root, run:
# rails runner db/import_topics_from_old_db.rb

filepath_topics = "old_db/topics/"

def importTopic(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  imported_topic = Topic.new(
    title: data['title'] || 'title',
    subtitle: data['subtitle'] || 'subtitle',
    description: data['description'] || 'description'
  )
  puts imported_topic
  unless imported_topic.valid?
    puts "### #{imported_topic.title} not imported ! ###"
    panic
  end
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
