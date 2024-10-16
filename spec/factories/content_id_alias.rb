FactoryBot.define do
  factory :content_id_alias do
    sequence(:name) { |n| "friendly-id-#{n}" }
    content_id { SecureRandom.uuid }
  end
end
