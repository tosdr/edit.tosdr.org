# in repo root, run:
# rails runner db/export_documents_to_tosback.rb

require 'json'

filepath_rules = "../tosback2/rules/"

puts "Exporting documents..."
Document.includes(:service).each do |doc|
  puts 'CONSIDERING DOC:', doc.url, doc.name
  begin
    filecontent = File.open(filepath_rules + doc.service.url.split(',')[0] + '.xml')
    ngxml = Nokogiri::XML(filecontent)
    filecontent.close
  
    site = ngxml.xpath("//sitename[1]/@name").to_s
    puts 'LOOKING AT RULE:', site
    ngxml.xpath("//sitename/docname").each do |doc|
      name = doc.at_xpath("./@name").to_s
      url = doc.at_xpath("./url/@name").to_s
      xpath = doc.at_xpath("./url/@xpath").to_s
      reviewed = (doc.at_xpath("./url/@reviewed").to_s == "true")
      puts 'HAVE DOC:', name, url, xpath, reviewed
    end
  rescue
   puts 'new file?'
  end
end

puts "Finishing exporting documents"
puts "Done!"
