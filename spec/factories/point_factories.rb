require 'faker'

FactoryBot.define do
  factory :point do
    service
    document

    title { Faker::Name.unique.name }
    source { Faker::Internet.url }
    status { ['approved', 'pending', 'declined'].sample }
  end
end
