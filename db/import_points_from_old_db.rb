require 'json'
require 'pry'

# in repo root, run:
# rails runner db/import_points_from_old_db.rb

filepath_points = "old_db/points/"

$featured_counts = {}

def importPoint(data, service)
  puts 'old data:'
  puts data
  puts service
  puts 'new data:'
  userObj = User.find_by_email('admintest@email.com')
  topicObj = Topic.find_by_title('Personal Data')
  serviceObjDefault = Service.find_by_name('amazon')
  serviceObj = Service.find_by_name(service) || serviceObjDefault
  caseObjDefault = Case.find_by_title('info given about security practices')
  caseObj = Case.find_by_title(data['tosdr']['case']) || caseObjDefault

  if data['disputed']
    status = 'disputed'
  elsif data['irrelevant']
    status = 'declined'
  elsif data['tosdr'] && data['tosdr']['point'] && data['tosdr']['score']
    status = 'approved'
  else
    status = 'pending'
  end

  puts 'checking featured counts'
  puts serviceObj.id
  if !$featured_counts[serviceObj.id]
    $featured_counts[serviceObj.id] = 0
  end
  if $featured_counts[serviceObj.id] < 5
    is_featured = true
    $featured_counts[serviceObj.id] += 1
  else
    is_featured = false
  end

  imported_point = Point.new(
    oldId: data['id'],
    title: data['title'],
    user: userObj,
    source: data['discussion'],
    status: status,
    analysis: data['tosdr'] ? data['tosdr']['tldr'] : '',
    rating: (data['tosdr'] && data['tosdr']['score']) ? data['tosdr']['score'] / 10 : 0,
    topic: topicObj,
    service: serviceObj,
    case_id: caseObj.id,
    is_featured: is_featured
  )

#  validates :title, presence: true
#  validates :title, length: { in: 5..140 }
#  validates :source, presence: true
#  validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed", "draft"], allow_nil: false }
#  validates :analysis, presence: true
#  validates :rating, presence: true
#  validates :rating, numericality: true

  unless imported_point.valid?
    puts "### #{imported_point.title} not imported ! ###"
    # panic
  end
#    binding.pry
#    service_id: service.id,
#    topic = Topic.find_by_title(line['topics']) #need to import the services first and match it by string
#    topic_id: topic.id, #need to import topics first and match it by string
  imported_point.save
  puts imported_point.id
  puts data['id']
  creationComment = Comment.new(
    point: imported_point,
    summary: 'imported from '+data['id']
  )
  creationComment.save
  puts 'saved.'
end

puts "Importing points..."
Dir.foreach(filepath_points) do |filename|
  next if filename == '.' or filename == '..' or filename == 'README.md'
  file = File.read(filepath_points + filename)
  data = JSON.parse(file)
  for i in 0 ... data['services'].size
    importPoint(data, data['services'][i])
  end
end
puts "Finishing importing points"
puts "Done!"
