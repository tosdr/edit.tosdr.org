# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts "Cleaning up the database..."
User.destroy_all
Reason.destroy_all
Point.destroy_all
Service.destroy_all
Topic.destroy_all

puts "Starts new seeding"
test_user = User.new(email: "test@email.com", username: "test user", password: "testnonadminuser", password_confirmation: "testnonadminuser")
test_user.save
curator_test_user = User.new(email: "curatortest@email.com", password: "testcuratoruser", password_confirmation: "testcuratoruser", curator: true)
curator_test_user.save
admin_test_user = User.new(email: "admintest@email.com", username: "admin test user", password: "testadminuser", password_confirmation: "testadminuser", admin: true)
admin_test_user.save

puts "Importing topics"
load File.join(Rails.root,"db","import_topics_from_old_db.rb")
puts "Importing services"
load File.join(Rails.root,"db","import_services_from_old_db.rb")
puts "Importing cases"
load File.join(Rails.root,"db","import_cases_from_old_db.rb")
puts "Importing points"
load File.join(Rails.root,"db","import_points_from_old_db.rb")
puts "Importing posts"
load File.join(Rails.root,"db","import_posts_from_old_db.rb")
puts "Done!"
