FactoryGirl.define do
  factory :link do
    target_content_id { SecureRandom.uuid }
    link_type         { "organisations" }
  end
end
