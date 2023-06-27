require 'nokogiri'

# in repo root, run:
# rails runner db/import_tosback2_rules.rb

$tosback2_repo = "https://github.com/tosdr/tosback2"
$rules_path = "tosback2/rules/" # Directories should include trailing slash
$crawls_path = {
  true => "tosback2/crawl_reviewed/",
  false => "tosback2/crawl/"
}
$crawls_separator = "/"
$crawls_extension = ".txt"

def importRules
  Dir.foreach($rules_path) do |xml_file| # loop for each xml file/rule
    next if xml_file == "." || xml_file == ".."
    
    filecontent = File.open($rules_path + xml_file)
    ngxml = Nokogiri::XML(filecontent)
    filecontent.close
  
    site = ngxml.xpath("//sitename[1]/@name").to_s
    services = Service.where('url LIKE ?', "#{site}%")
    if (services.length != 1)
      # puts 'found ' + services.length.to_s + ' services for: ' + site
    else
      puts 'service for ' + site + ' is ' + services[0].name
      ngxml.xpath("//sitename/docname").each do |doc|
        name = doc.at_xpath("./@name").to_s
        url = doc.at_xpath("./url/@name").to_s
        xpath = doc.at_xpath("./url/@xpath").to_s
        reviewed = (doc.at_xpath("./url/@reviewed").to_s == "true")
        text = File.read($crawls_path[reviewed] + site + $crawls_separator + name + $crawls_extension)
        # puts url
        doc = Document.find_by_url(url)
        if (!doc)
          puts 'new: ' + url
          doc = Document.new()
        else
          if text.eql?(doc.text)
            # puts 'document text unchanged!'
          else
            docPoints = doc.points
            puts docPoints
            docPoints.each do |p|
              quote_start = text.index(p.quote_text)
              if (quote_start.nil?)
                comment = Comment.create({
                  point: p,
                  summary: 'Cannot find this point in the updated document, manual review required!'
                })
                if (comment.errors.full_messages.length > 0)
                  puts comment.errors.full_messages
                  panic()
                end
                p.status = 'pending'
                if (p.case_id.nil?)
                  p.case = Case.find_by_title('none')
                end
                if (!p.save())
                  puts p.errors.full_messages
                  panic()
                end
              else
                quote_end = quote_start + p.quote_text.length
                if (quote_start != p.quote_start || quote_end != p.quote_end)
                  puts 'reindexing point ' + p.id + ' (' + p.quote_start + ' -> ' + quote_start + ', ' +p.quote_end + ' -> ' + quote_end +  ')'
                  p.update({
                    quote_start: quote_start,
                    quote_end: quote_end
                  })
                  if (!p.save())
                    puts p.errors.full_messages
                    panic()
                  end
                end
              end
            end
          end
        end
        # puts 'updating'
        doc.update({
          service: services[0],
          name: name,
          url: url,
          xpath: xpath,
          reviewed: reviewed,
          text: text
        })
        # puts 'saving'
        if (!doc.save())
          puts doc.errors.full_messages
          panic()
        end
      end
    end
  end
end

puts "Cloning " + $tosback2_repo
`git clone --depth=1 #{$tosback2_repo}`

puts "Importing rules..."
importRules()
puts "Done!"
