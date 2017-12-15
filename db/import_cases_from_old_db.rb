# in repo root, run:
# rails runner db/import_cases_from_old_db.rb

filename_cases = "old_db/cases.json"

def importCase(data)
  puts 'old data:'
  puts data 
  puts 'new data:'
  topic = Topic.find_by_oldId(data['topic'])
  imported_case = Case.new(
    title: data['name'],
    classification: data['point'],
    score: data['score'],
    topic: topic
  )
  puts imported_case
  unless imported_case.valid?
    puts "### #{imported_case.title} not imported ! ###" #+ panic
    puts topic
  end
  imported_case.save
  puts 'saved.'
end

puts "Importing cases..."
file = File.read(filename_cases)
data = JSON.parse(file)
data.each { |line| importCase(line) }
puts "Finishing importing cases"
puts "Done!"
