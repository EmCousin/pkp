FactoryBot.define do
  factory :member do
    first_name { "MyString" }
    last_name { "MyString" }
    birthdate { "2020-07-14" }
    contact_name { "MyString" }
    contact_phone_number { "MyString" }
    contact_relationship { "MyString" }
    agreed_to_advertising_right { false }
  end
end
