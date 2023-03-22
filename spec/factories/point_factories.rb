require 'faker'

FactoryBot.define do
  factory :point do
    service

    title { Faker::Name.unique.name }
    source { Faker::Internet.url }
    status { ['approved', 'pending', 'declined', 'changes-requested', 'draft', 'approved-not-found', 'pending-not-found'].sample }
  end
end
