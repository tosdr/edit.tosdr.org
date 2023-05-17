require 'faker'

FactoryBot.define do
  factory :topic do
    title { Faker::Name.unique.name }
    subtitle { Faker::Lorem.word }
    description { Faker::Lorem.sentence }

    factory :topic_with_points do
      transient do
        point_count { 2 }
      end

      after(:create) do |_topic_object, evaluator|
        create_list(:point, evaluator.point_count)
      end
    end
  end
end