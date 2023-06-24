# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts "Cleaning up the database..."
User.destroy_all

puts "Starts new seeding"

admin_test_user = User.new(email: "admin@selfhosted.tosdr.org", username: "admin", password: "admin", password_confirmation: "admin", admin: true, curator: true, confirmed_at: Time.zone.now.beginning_of_day)
admin_test_user.save(:validate => false)
puts admin_test_user.errors.full_messages
puts "You can log in with admin@selfhosted.tosdr.org / admin to add services, topics, cases, points and appoint users as curators"