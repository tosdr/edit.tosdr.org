FactoryBot.define do
  password = 'Justforseedjustforseed1'

  factory :user do
    sequence(:email) { |n| "moleary#{n}@test.org" }
    sequence(:username) { |n| "moleary#{n}" }
    password { password }
    password_confirmation { password }
    admin { true }
    curator { true }
    verified_contributor { false }

    factory :user_confirmed do
      after(:create) do |user|
        user.confirm
      end
    end
  end
end
