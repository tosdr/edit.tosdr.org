require 'faker'

FactoryBot.define do
  factory :case do
    topic

    title { Faker::Name.unique.name }

    factory :case_with_points do
      transient do
        point_count { 2 }
      end

      after(:create) do |case_ref, evaluator|
        create_list(:point, evaluator.point_count, case_id: case_ref.id, case: case_ref, topic: case_ref.topic)
      end
    end
  end
end