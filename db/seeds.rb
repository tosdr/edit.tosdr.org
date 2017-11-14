# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts "Starts seeding"
test_user = User.new(email: "test@email.com", username: "test user", password: "testnonadminuser", password_confirmation: "testnonadminuser")
test_user.save
test_service = Service.new(name: "Test service", url: "http://perdu.com", grade: "A")
test_service.save
test_topic = Topic.new(title: "Test topic", subtitle: "Test subtitle", description: "Test topic description")
test_topic.save
test_point_1 = Point.new(user_id: 1, title: "Test point 1", source: "http://perdu.com", status: "pending", analysis: "Bla bla bla", rating: 3, topic_id: 1)
test_point_1.save
test_point_2 = Point.new(user_id: 1, title: "Test point 2", source: "http://perdu.com", status: "pending", analysis: "Bla bla bla", rating: 5, topic_id: 1)
test_point_2.save
puts "Done!"
