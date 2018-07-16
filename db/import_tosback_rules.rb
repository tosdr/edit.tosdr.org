require 'nokogiri'

# in repo root, run:
# rails runner db/import_tosback2_rules.rb

$tosback2_repo = "https://github.com/tosdr/tosback2"
$rules_path = "tosback2/rules/" # Directories should include trailing slash

def importRules()
  Dir.foreach($rules_path) do |xml_file| # loop for each xml file/rule
    next if xml_file == "." || xml_file == ".."
    
    filecontent = File.open($rules_path + xml_file)
    ngxml = Nokogiri::XML(filecontent)
    filecontent.close
  
    site = ngxml.xpath("//sitename[1]/@name").to_s
    services = Service.where('url LIKE ?', "#{site}%")
    if (services.length != 1)
      puts 'found ' + services.length.to_s + ' services for: ' + site
    else
      puts 'service for ' + site + ' is ' + services[0].name
      ngxml.xpath("//sitename/docname").each do |doc|
        name = doc.at_xpath("./@name").to_s
        url = doc.at_xpath("./url/@name").to_s
        xpath = doc.at_xpath("./url/@xpath").to_s
        reviewed = doc.at_xpath("./url/@reviewed").to_s
        puts url
        doc = Document.find_by_url(url)
        if (!doc)
          puts 'new: ' + url
          doc = Document.new()
        end
        puts 'updating'
        doc.update({
          service: services[0],
          name: name,
          url: url,
          xpath: xpath,
          reviewed: reviewed
        })
        puts 'saving'
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
