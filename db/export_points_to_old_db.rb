# in repo root, run:
# rails runner db/export_points_to_old_db.rb

require 'json'

filepath_points = "../tosdr-build/src/points/"
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
    data = {}
    data['tosdr'] = {}
    puts 'new file ' + filename
  end
  data['id'] = point.id.to_s
  data['title'] = point.title
  data['quoteDoc'] = point.quoteDoc if point.quoteDoc && point.quoteDoc.length > 0
  data['quoteRev'] = point.quoteRev if point.quoteRev && point.quoteRev.length > 0
  data['quoteStart'] = point.quoteStart if point.quoteStart
  data['quoteEnd'] = point.quoteEnd if point.quoteEnd
  data['quoteText'] = point.quoteText if point.quoteText && point.quoteText.length > 0
  data['tosdr']['tldr'] = point.analysis
  if (!point.case_id.nil?) # if case is nil then we don't export the point status
    if (point.status == 'approved')
      data['needModeration'] = false if data['needModeration']
      data['tosdr']['irrelevant'] = false if data['tosdr']['irrelevant']
    elsif (point.status == 'declined')
      data['needModeration'] = false if data['needModeration']
      data['tosdr']['irrelevant'] = true if !data['tosdr']['irrelevant']
    else # status is 'draft', 'pending', 'disputed', or unknown
      data['needModeration'] = true if !data['needModeration']
      data['tosdr']['irrelevant'] = false if data['tosdr']['irrelevant']
    end
    data['tosdr']['score'] = point.case.score
    data['tosdr']['point'] = point.case.classification
  end

  if (data['services'].nil?) then
    data['services'] = [ point.service.slug ]
  end

  if (mapping['toId'][ point.oldId ])
    puts '------------'
    puts (point.oldId )
    puts mapping['toId'][ point.oldId ]
    puts point.id.to_s
  end
  mapping['toId'][point.oldId] = point.id.to_s

  if (mapping['toSlug'][point.id.to_s])
    puts point.id.to_s
    puts mapping['toSlug'][point.id.to_s]
    puts point.oldId
    panic()
  end
  mapping['toSlug'][point.id.to_s] = point.oldId

  # puts "Writing " + filepath_points + filename
  File.write(filepath_points + filename, JSON.pretty_unparse(data))
end
File.write(filepath_points_mapping, JSON.pretty_unparse(mapping))
puts "Finishing exporting points"
puts "Done!"
