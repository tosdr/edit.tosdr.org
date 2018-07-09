# in repo root, run:
# rails runner db/import_doc_revision.rb

tosback2_repo = "https://github.com/tosdr/tosback2"
filepath_docs = "./tosback2/crawl_reviewed/"

def importDocRevision(service, doc, rev)
  data = {}
  service = Service.where('"url" like \'' + service + '%\'')[0]
  if !service
    return
  end
  # puts 'checking'
  # puts service.id
  # puts doc
  # puts rev
  existing = DocRevision.where(
    service_id: service.id,
    name: doc,
    revision: rev
  )
  # puts existing.length
  if existing.length > 0
    # puts 'existing!'
    return
  end
  puts 'importing'
  imported = DocRevision.new(
    service_id: service.id,
    name: doc,
    revision: rev
  )
  puts service.id
  puts doc
  puts rev
  unless imported.valid?
    puts "### not imported ! ###"
    panic
  end
  imported.save
end

puts "Cloning " + tosback2_repo
`git clone --depth=1 #{tosback2_repo}`

puts "Importing docs..."
Dir.foreach(filepath_docs) do |service|
  next if service == '.' or service == '..'
  filepath_service = filepath_docs + service + '/'
  # puts filepath_service
  Dir.foreach(filepath_service) do |doc|
    filepath_doc = filepath_service + doc
    # puts filepath_doc
    next if doc == '.' or doc == '..'
    cmd = 'cd ' + filepath_docs + '; git log "' + service + '/' + doc + '"'
    # puts cmd
    rev = `#{cmd}`.split(' ')[1]
    # puts rev
    importDocRevision(service, doc, rev)
  end
end
puts "Done!"
