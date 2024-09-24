FactoryBot.define do
  factory :embedded_content_reference do
    friendly_id { "my-id" }
    content_id { SecureRandom.uuid }
  end
end
