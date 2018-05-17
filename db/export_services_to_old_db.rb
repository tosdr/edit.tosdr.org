# in repo root, run:
# rails runner db/export_services_to_old_db.rb

require 'json'

filepath_services = "../tosdr-build/src/services/"
filepath_services_migrated = "../tosdr-build/src/servicesMigrated/"
filepath_services_mapping = "../tosdr-build/src/servicesMapping.json"

mapping = {}
mapping['toId'] = {}
mapping['toSlug'] = {}


puts "Exporting services..."
Service.all.each do |service|
  # puts service.to_json

  if service.slug != 'none'
    filename = (service.slug || service.name.split('.').join('-')).downcase + '.json'
    # File.delete(filepath_services + filename)
    # filename = service.id.to_s + '.json'
    begin
      puts filename
      file = File.read(filepath_services + filename)
      puts 'YES'
      data = JSON.parse(file)
    rescue
      puts 'NO'
      data = {}
      # puts 'new file ' + filename
    end
    data['tosdr'] = data['tosdr'] || {}
    data['meta'] = data['meta'] || {}

    data['id'] = service.id
    data['name'] = service.name
    data['keywords'] = service.keywords ? service.keywords.split(',') : []
    data['related'] = service.related ? service.related.split(',') : []
    goodUrls = data['urls'] ? data['urls'].join(',') : ''
    if service.url != goodUrls then
      puts service.id.to_s + ' ' + service.url + ' <- ' + goodUrls
    end
    data['urls'] = service.url.split(',')
    # data['tosdr']['rated'] = service.grade
    data['meta']['spec-version'] = '1.1'

    data['slug'] = (service.slug || service.name.split('.').join('-')).downcase

    if (mapping['toId'][ (service.slug || service.name.split('.').join('-')).downcase ])
      puts (service.slug || service.name.split('.').join('-')).downcase
      puts mapping['toId'][ (service.slug || service.name.split('.').join('-')).downcase ]
      puts service.id.to_s
      panic()
    end
    mapping['toId'][ (service.slug || service.name.split('.').join('-')).downcase ] = service.id.to_s

    if (mapping['toSlug'][service.id.to_s])
      puts service.id.to_s
      puts mapping['toSlug'][service.id.to_s]
      puts (service.slug || service.name.split('.').join('-')).downcase
      panic()
    end
    mapping['toSlug'][service.id.to_s] = (service.slug || service.name.split('.').join('-')).downcase

    # migrate:
    migratedFilename = service.id.to_s + '.json'
    File.write(filepath_services + filename, JSON.pretty_unparse(data))
    File.write(filepath_services_migrated + migratedFilename, JSON.pretty_unparse(data))
  end
end
File.write(filepath_services_mapping, JSON.pretty_unparse(mapping))

puts "Finishing exporting services"
puts "Done!"
