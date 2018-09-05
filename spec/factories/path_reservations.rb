# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :path_reservation do
    sequence(:base_path) { |n| "/path#{n}" }
    publishing_app { "publisher" }
  end
end
