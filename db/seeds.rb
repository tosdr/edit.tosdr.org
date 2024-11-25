# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts 'Starting seeding...'

puts 'Seeding users'

password = 'Justforseed1'

users = [
  User.new(email: 'admin@selfhosted.tosdr.org', username: 'tosdr_admin', password: password,
           password_confirmation: password, admin: true, curator: true),
  User.new(email: 'curator@selfhosted.tosdr.org', username: 'tosdr_curator', password: password,
           password_confirmation: password, admin: false, curator: true),
  User.new(email: 'user@selfhosted.tosdr.org', username: 'tosdr_user', password: password,
           password_confirmation: password, admin: false, curator: false)
]

users.each do |user|
  user.confirm
  user.save! validate: false
end

puts "#{users.length} users added!"

puts 'Seeding services'

services = [
  Service.new(name: 'YouTube_dev', url: 'youtube_dev.com'),
  Service.new(name: 'Facebook_dev', url: 'facebook_dev.com'),
  Service.new(name: 'Wikipedia_dev', url: 'wikipedia_dev.org')
]

services.each do |service|
  service.save! validate: false
end

puts "#{services.length} services added!"

puts 'Seeding topics'

documentTypes = [
  DocumentType.new(name: 'Terms of Service', status: 'approved')
]

documentTypes.each do |documentType|
  documentType.save! validate: false
end

puts "#{services.length} document types added!"

topics = [
  Topic.new(title: 'Personal Data Dev', subtitle: 'Can you control your privacy?',
            description: 'How much control do you have over how your data will be used?'),
  Topic.new(title: 'Third Parties Dev', subtitle: 'Data Processors, Social Media Services, Ad Services',
            description: 'How much data is processed by external companies?'),
  Topic.new(title: 'Notice of Changing Terms Dev', subtitle: 'Are users notified when terms change?',
            description: 'Updates and changes to terms of service and privacy policies need to be communicated to users.')
]

topics.each do |topic|
  topic.save! validate: false
end

puts "#{topics.length} topics added!"

puts 'Seeding cases'

personal_data = Topic.find_by_title('Personal Data Dev')
third_parties = Topic.find_by_title('Third Parties Dev')
notice = Topic.find_by_title('Notice of Changing Terms Dev')

cases = [
  Case.new(title: 'Dev Your personal information is used for many different purposes', classification: 'bad',
           topic_id: personal_data.id),
  Case.new(title: 'Dev Third parties are involved in operating the service', classification: 'neutral',
           topic_id: third_parties.id),
  Case.new(title: 'Dev Terms may be changed any time at their discretion, without notice to you',
           classification: 'bad', topic_id: notice.id)
]

cases.each do |c|
  c.save! validate: false
end

puts "#{cases.length} cases added!"

puts 'Seeding documents'

youtube_text = <<~TEXT
  We may also collect information about you from trusted partners, including marketing partners who provide us with information about potential customers of our business services, and security partners who provide us with information to protect against abuse.
  We also receive information from advertisers to provide advertising and research services on their behalf.</p> <p> We use various technologies to collect and store information, including cookies, pixel tags, local storage, such as browser web storage or application data caches, databases, and server logs.</p>Why Google collects data<p>We use data to build better services</p> <p>We use the information we collect from all our services for the following purposes:</p>Provide our services<p>We use your information to deliver our services, like processing the terms you search for in order to return results or helping you share content by suggesting recipients from your contacts
TEXT

facebook_text = <<~TEXT
  We use cookies to better understand how people use the Facebook Products so that we can improve them. <i>For example:</i> Cookies can help us understand how people use the Facebook service, analyse which parts of the Facebook Products people find most useful and engaging, and identify features that could be improved. Google Analytics We also set cookies from the Facebook.com domain that work with the Google Analytics service to help us understand how businesses use Facebook's developer sites. These cookies have names such as __utma, __utmb, __utmc, __utmz, __qca and _ga. Third-party websites and apps
  Our business partners may also choose to share information with Facebook from cookies set in their own websites' domains, whether or not you have a Facebook account or are logged in. Specifically, cookies named _fbc or _fbp may be set on the domain of the Facebook business partner whose site you're visiting. Unlike cookies that are set on Facebook's own domains, these cookies arent accessible by Facebook when you're on a site other than the one on which they were set, including when you are on one of our domains. They serve the same purposes as cookies set in Facebook's own domain, which are to personalise content (including ads), measure ads, produce analytics and provide a safer experience, as set out in this Cookies Policy. <i>
TEXT

wikipedia_text = <<~TEXT
  Because we believe that you shouldnt have to provide personal information to participate in the free knowledge movement, you may: Read, edit, or use any Wikimedia Site without registering an account. Register for an account without providing an email address or real name.</li> </ul> <p> <b>Because we want to understand how Wikimedia Sites are used so we can make them better for you, we collect some information when you:</b> </p> <ul> <li>Make public contributions.</li> <li>Register an account or update your user page.</li> <li>Use the Wikimedia Sites.</li> <li>Send us emails or participate in a survey or give feedback.</li> </ul> <p> <b>We are committed to:</b> </p> <ul> <li>Describing how your information may be used or shared in this Privacy Policy.</li> <li>Using reasonable measures to keep your information secure.</li> <li>Never selling your information or sharing it with third parties for marketing purposes.</li> <li>Only sharing your information in limited circumstances, such as to improve the Wikimedia Sites, to comply with the law, or to protect you and others.</li> <li>Retaining your data for the shortest possible time that is consistent with maintaining, understanding, and improving the Wikimedia Sites, and our obligations under applicable law.</li> </ul>
TEXT

documents = [
  Document.new(name: 'Privacy Policy', service_id: Service.find_by_name('YouTube_dev').id, text: youtube_text),
  Document.new(name: 'Cookie Police', service_id: Service.find_by_name('Facebook_dev').id, text: facebook_text),
  Document.new(name: 'Privacy Policy', service_id: Service.find_by_name('Wikipedia_dev'), text: wikipedia_text)
]

documents.each do |doc|
  doc.save! validate: false
end

puts "#{documents.length} documents added!"

puts 'seeding docbot-created points'

docbot = User.docbot_user

unless docbot
  docbot = User.new(email: 'docbot@test.org', username: 'docbot', admin: true, curator: true)
  docbot.confirm
  docbot.save! validate: false
  docbot.reload
end

services = Service.pluck(:id)
cases = Case.pluck(:id)
documents = Document.pluck(:id)

100.times do
  service_id = services.sample
  case_id = cases.sample
  title = Case.find(case_id).title
  document_id = documents.sample
  ml_score = Faker::Number.between(from: 0.0, to: 1.0).round(2)
  Point.create!(title: title, case_id: case_id, service_id: service_id, document_id: document_id, ml_score: ml_score,
                user_id: docbot.id, status: 'pending')
end
