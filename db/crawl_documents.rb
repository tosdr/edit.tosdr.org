require "#{Rails.root}/lib/tosbackdoc.rb"

# Edit config/database.yml so that development has url: DATABASE_URL.
# Then in repo root, run:
# export DATABASE_URL=`heroku config:get DATABASE_URL --app edit-tosdr-org`
# FROM_ID=151 TO_ID=160 USER_ID=789 rails runner db/crawl_documents.rb

$fromId = ENV['FROM_ID']
$toId = ENV['TO_ID']
$userId = ENV['USER_ID']

puts "Crawling documents.."
Document.where(:id => $fromId..$toId, :status => nil).each do |document|
  puts 'Starting ' + document.id.to_s
  begin
    puts 'crawling ' + document.url + ' (' + document.xpath + ')'
    @tbdoc = TOSBackDoc.new({
      url: document.url,
      xpath: document.xpath
    })

    @tbdoc.scrape

    oldLength = document.text.length
    puts 'old length ' + oldLength.to_s
    document.update(text: @tbdoc.newdata)
    newLength = document.text.length
    puts 'new length ' + newLength.to_s

    if (newLength == 0 && document.xpath != nil)
      puts 'Retrying without xpath'
      @tbdoc2 = TOSBackDoc.new({
        url: document.url,
        xpath: nil
      })
      @tbdoc2.scrape
      if (@tbdoc2.newdata.length > 0)
        puts 'Using this with length ' + @tbdoc2.newdata.length.to_s
        newLength = @tbdoc2.newdata.length
        document.update(text: @tbdoc2.newdata, xpath: nil)
      end
    end
    @document_comment = DocumentComment.new()
    @document_comment.summary = 'Crawled, old length: ' + oldLength.to_s + ', new length: ' + newLength.to_s
    @document_comment.user_id = $userId
    @document_comment.document_id = document.id

    if @document_comment.save
      puts "Comment added!"
    else
      puts "Error adding comment!"
      puts @document_comment.errors.full_messages
    end
    puts 'Done ' + document.id.to_s
  rescue
    puts 'Fail ' + document.id.to_s
  end
  puts '---'
end
puts "Finished crawling documents!"
