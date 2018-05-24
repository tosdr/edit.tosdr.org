# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts "Cleaning up the database..."
Reason.destroy_all
Comment.destroy_all
Reason.destroy_all
Point.destroy_all
Service.destroy_all
Case.destroy_all
Topic.destroy_all
User.destroy_all

puts "Starts new seeding"
test_user = User.new(email: "test@email.com", username: "test user", password: "testnonadminuser", password_confirmation: "testnonadminuser")
test_user.save
puts "You can log in with test@email.com / testnonadminuser"
curator_test_user = User.new(email: "curatortest@email.com", password: "testcuratoruser", password_confirmation: "testcuratoruser", curator: true)
curator_test_user.save
puts "You can log in with curatortest@email.com / testcuratoruser"
admin_test_user = User.new(email: "admintest@email.com", username: "admin test user", password: "testadminuser", password_confirmation: "testadminuser", admin: true)
admin_test_user.save
puts "You can log in with admintest@email.com / testadminuser"

puts "Done! Now run 'rails server' and visit http://localhost:3000"
