# in repo root, run:
# rails runner db/import_posts_from_old_db.rb


filename_posts = "old_db/posts.json"

def importPost(line, index)
  # puts 'old data:'
  # puts $data[index]
  # puts 'new data:'
  point = Point.find_by_oldId(line['thread'])
  if (point)
    $found = false
    def check(commentId, summary, contents1, contents2)
      if (summary == contents1)
        comment = Comment.find(commentId)
        comment.summary = contents2
        comment.save
        $found = true
      elsif (summary == contents2)
        $found = true
      end
    end
    # puts line
    contents2 = 'https://groups.google.com/forum/#!msg/tosdr/' + line['thread'] + '/' + line['threadEntry'] + ' ' + (line['contents'] || '?')
    point.comments.each { | comment | check(comment.id, comment.summary, line['contents'], contents2) }
    if ($found)
      # puts 'found!' + point.id.to_s
    else
      imported_post = Comment.new(
        summary: contents2,
        point: point
      )
      # puts imported_post
      unless imported_post.valid?
        # puts "### #{imported_post.summary} not imported ! ###" #+ panic
      end
      imported_post.save
      # puts 'saved.'
      # puts imported_post.errors.full_messages
    end
#    $data[index]['point_id'] = point.id
  else
    puts line['filename']
  end
end

puts "Importing posts..."
file = File.read(filename_posts)
$data = JSON.parse(file)
$data.each_with_index { |line, index| importPost(line, index) }
#   output = "[\r\n\r\n"
#   $data.each { |line| output += JSON.unparse(line) + ",\r\n\r\n" }
#   output += "{}]\r\n"
#   File.write(filename_posts, output)
puts "Finishing importing posts"
puts "Done!"
