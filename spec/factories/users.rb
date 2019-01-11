FactoryBot.define do
  factory :user do
    name {"Georg_#{rand(999)}"}

    sequence(:email) { |n| "somebody_#{n}@mail.ru?"}

    is_admin false

    balance 0

    after(:build) { |u| u.password_confirmation = u.password = '123456'}
  end
end