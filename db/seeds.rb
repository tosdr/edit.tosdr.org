# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# puts "Cleaning up the database..."
# Reason.destroy_all
# Point.destroy_all
# Service.destroy_all
# Topic.destroy_all
# puts "Importing topics"
# load File.join(Rails.root,"db","import_topics_from_old_db.rb")
# puts "Importing services"
# load File.join(Rails.root,"db","import_services_from_old_db.rb")
# load File.join(Rails.root,"db","import_points_from_old_db.rb")

puts "Starts new seeding"
test_user = User.new(email: "test@email.com", username: "test user", password: "testnonadminuser", password_confirmation: "testnonadminuser")
test_user.save
admin_test_user = User.new(email: "admintest@email.com", username: "admin test user", password: "testadminuser", password_confirmation: "testadminuser", admin: true)
admin_test_user.save
test_service_1 = Service.new(name: "Test service 1", url: "http://perdu.com", grade: "A")
test_service_1.save
test_service_2 = Service.new(name: "Test service 2", url: "http://perdu.com", grade: "B")
test_service_2.save
test_topic = Topic.new(title: "Test topic", subtitle: "Test subtitle", description: "Test topic description")
test_topic.save
test_point_1 = Point.new(user_id: 1, title: "Test point 1", source: "http://perdu.com", status: "pending", analysis: "Bla bla bla", rating: 3, topic_id: 1, service_id: 1)
test_point_1.save
test_point_2 = Point.new(user_id: 1, title: "Test point 2", source: "http://perdu.com", status: "pending", analysis: "Bla bla bla", rating: 5, topic_id: 1, service_id: 1)
test_point_2.save
puts "Done!"
