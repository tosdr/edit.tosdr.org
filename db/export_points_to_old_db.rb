# in repo root, run:
# rails runner db/export_points_to_old_db.rb

require 'json'

filepath_points = "../tosdr-build/src/points/"
filepath_points_migrated = "../tosdr-build/src/pointsMigrated/"
filepath_points_mapping = "../tosdr-build/src/pointsMapping.json"

mapping = {}
mapping['toId'] = {}
mapping['toSlug'] = {}

puts "Exporting points..."
Point.all.each do |point|
  # puts point.to_json
  # puts point.service.to_json
  if (point.oldId.nil?) then 
    point['oldId'] = point.id.to_s
  end
  # puts point.to_json
  filename = point.id.to_s + '.json'
  begin
    file = File.read(filepath_points + filename)
    data = JSON.parse(file)
  rescue
    begin
      filename = point.oldId + '-' + point.service.slug + '.json'
      file = File.read(filepath_points + filename)
      data = JSON.parse(file)
    rescue
      begin
        filename = point.oldId + '.json'
        file = File.read(filepath_points + filename)
        data = JSON.parse(file)
      rescue
        data = {}
        data['tosdr'] = {}
        puts 'new file ' + filename
      end
    end
  end
  data['id'] = point.id.to_s
  data['title'] = point.title
  data['tosdr']['tldr'] = point.analysis
  # data['tosdr']['tmp_rating'] = point.rating
  if (data['services'].nil?) then
    data['services'] = [ point.service.slug ]
  end
  # migrate to phoenix id's in filenames:
  migratedFilename = point.id.to_s + '.json'

  if (mapping['toId'][ point.oldId ])
    puts '------------'
    puts '------------'
    puts '------------'
    puts '------------'
    puts '------------'
    puts (point.oldId )
    puts mapping['toId'][ point.oldId ]
    puts point.id.to_s
    puts '------------'
    puts '------------'
    puts '------------'
    puts '------------'
    puts '------------'
  end
  mapping['toId'][point.oldId] = point.id.to_s

  if (mapping['toSlug'][point.id.to_s])
    puts point.id.to_s
    puts mapping['toSlug'][point.id.to_s]
    puts (point.oldId || point.name.split('.').join('-')).downcase
    panic()
  end
  mapping['toSlug'][point.id.to_s] = (point.oldId || point.name.split('.').join('-')).downcase

  # puts "Writing " + filepath_points + filename
  File.write(filepath_points + filename, JSON.pretty_unparse(data))
  File.write(filepath_points_migrated + migratedFilename, JSON.pretty_unparse(data))
end
File.write(filepath_points_mapping, JSON.pretty_unparse(mapping))
puts "Finishing exporting points"
puts "Done!"
