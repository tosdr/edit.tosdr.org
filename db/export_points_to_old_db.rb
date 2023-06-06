# in repo root, run:
# rails runner db/export_points_to_old_db.rb

require 'json'

filepath_points = "../tosdr.org/src/points/"
filepath_points_mapping = "../tosdr.org/src/pointsMapping.json"

mapping = {}
mapping['toId'] = {}
mapping['toSlug'] = {}

puts "Exporting points..."
Point.all.each do |point|
  # puts point.to_json
  # puts point.service.to_json
  if (point.old_id.nil?) then 
    point['old_id'] = point.id.to_s
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
  data['quoteDoc'] = point.document.name if point.document
  # data['quoteRev'] = "latest"
  data['quoteStart'] = point.quote_start if point.quote_start
  data['quoteEnd'] = point.quote_end if point.quote_end
  data['quoteText'] = point.quote_text if point.quote_text && point.quote_text.length > 0
  data['tosdr']['tldr'] = point.analysis
  if (!point.case_id.nil? && point.case.title != 'none' && point.case.title.length > 0) # if case is nil then we don't export the point status
    if (point.status == 'approved')
      data['needModeration'] = false if data['needModeration']
      data['tosdr']['irrelevant'] = false if data['tosdr']['irrelevant']
    elsif (point.status == 'declined')
      data['needModeration'] = false if data['needModeration']
      data['tosdr']['irrelevant'] = true if !data['tosdr']['irrelevant']
    else # status is 'draft', 'pending', 'disputed', 'approved-not-found', 'pending-not-found', or unknown
      data['needModeration'] = true if !data['needModeration']
      data['tosdr']['irrelevant'] = false if data['tosdr']['irrelevant']
    end
    if (point.case.title != 'none')
      data['tosdr']['case'] = point.case.title
    end
  end
  serviceSlug = point.service.slug
  if (!serviceSlug || serviceSlug.length == 0)
    serviceSlug = point.service.name.gsub(' ', '').gsub('.', '-').downcase()
  end
  if (serviceSlug != 'none')
    data['services'] = [ serviceSlug ]
  end

  if (mapping['toId'][ point.old_id ])
    puts '------------'
    puts (point.old_id )
    puts mapping['toId'][ point.old_id ]
    puts point.id.to_s
  end
  mapping['toId'][point.old_id] = point.id.to_s

  if (mapping['toSlug'][point.id.to_s])
    puts point.id.to_s
    puts mapping['toSlug'][point.id.to_s]
    puts point.old_id
    panic()
  end
  mapping['toSlug'][point.id.to_s] = point.old_id

  # puts "Writing " + filepath_points + filename
  File.write(filepath_points + filename, JSON.pretty_unparse(data))
end
File.write(filepath_points_mapping, JSON.pretty_unparse(mapping))
puts "Finishing exporting points"
puts "Done!"
