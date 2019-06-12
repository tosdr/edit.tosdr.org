# in repo root, run:
# rails runner db/export_services_to_old_db.rb

require 'json'

filepath_cases = "../tosdr.org/src/cases/"

puts "Exporting cases..."
Case.all.each do |c|
  data = {}
  data['name'] = c.title
  data['point'] = c.classification
  data['privacyRelated'] = true if c.privacy_related
  data['score'] = c.score
  filename = data['name'].downcase().gsub(/[^a-z0-9]/, '_') + '.json'
  File.write(filepath_cases + filename, JSON.pretty_unparse(data))
end
puts "Done!"
