require 'faker'

FactoryBot.define do
  factory :document do
    service

    name { Faker::Name.unique.name }
    url { Faker::Internet.url }
  end
end