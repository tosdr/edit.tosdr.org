# in repo root, run:
# rails runner db/export_services_to_old_db.rb

require 'json'

filepath_cases = "../tosdr-build/src/cases/"

puts "Exporting cases..."
Case.all.each do |c|
  data = {}
  data['name'] = c.title
  data['point'] = c.classification
  data['score'] = c.score
  data['privacyRelated'] = c.privacy_related ? true : false
  filename = data['name'].downcase().gsub(/[^a-z0-9]/, '_') + '.json'
  File.write(filepath_cases + filename, JSON.pretty_unparse(data))
end
puts "Done!"
