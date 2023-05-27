require 'faker'

FactoryBot.define do
  factory :service do
    name { Faker::Name.unique.name }
    url { Faker::Internet.url }
  end
end