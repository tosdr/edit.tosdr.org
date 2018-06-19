# in repo root, run:
# rails runner db/import_doc_revision.rb

filepath_docs = "../tosback2/crawl_reviewed/"

def importDocRevision(service, doc, rev)
  data = {}
  data['service_id'] = Service.where('"url" like \'' + service + '%\'')[0].id
  data['name'] = doc
  data['revision'] = rev
  puts 'data:'
  puts data 
end

puts "Importing docs..."
Dir.foreach(filepath_docs) do |service|
  next if service == '.' or service == '..'
  filepath_service = filepath_docs + service + '/'
  puts filepath_service
  Dir.foreach(filepath_service) do |doc|
    filepath_doc = filepath_service + doc
    puts filepath_doc
    next if doc == '.' or doc == '..'
    cmd = 'cd ' + filepath_docs + '; git log "' + service + '/' + doc + '"'
    puts cmd
    rev = `#{cmd}`.split(' ')[1]
    puts rev
    importDocRevision(service, doc, rev)
  end
end
puts "Done!"
