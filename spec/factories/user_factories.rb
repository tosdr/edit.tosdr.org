FactoryBot.define do
  password = 'Justforseedjustforseed1'

  factory :user do
    email { 'moleary@test.org' }
    username { 'moleary' }
    password { password }
    password_confirmation { password }
    admin { true }
    curator { true }

    factory :user_confirmed do
      after(:create) do |user|
        user.confirm
      end
    end
  end
end
