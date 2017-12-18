# in repo root, run:
# rails runner db/import_posts_from_old_db.rb

filename_posts = "old_db/posts.json"

def importPost(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  point = Point.find_by_oldId(data['thread'])
  imported_post = Comment.new(
    summary: data['contents'],
    point: point
  )
  puts imported_post
  unless imported_post.valid?
    puts "### #{imported_post.summary} not imported ! ###" #+ panic
  end
  imported_post.save
  puts 'saved.'
end

puts "Importing posts..."
file = File.read(filename_posts)
data = JSON.parse(file)
data.each { |line| importPost(line) }
puts "Finishing importing posts"
puts "Done!"
