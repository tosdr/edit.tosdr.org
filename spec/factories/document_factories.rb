require 'faker'

FactoryBot.define do
  factory :document do
    service

    name { Faker::Name.unique.name }
    url { Faker::Internet.url }
    selector { 'body' }
    text { 'Example policy text for test points.' }
  end
end
