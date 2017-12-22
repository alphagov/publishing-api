FactoryBot.define do
  factory :link do
    link_set
    target_content_id { SecureRandom.uuid }
    link_type         { "organisations" }
  end
end
