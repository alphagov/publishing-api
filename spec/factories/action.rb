FactoryGirl.define do
  factory :action do
    content_id { SecureRandom.uuid }
    locale { "en" }
    action { "Action" }
    user_uid { SecureRandom.uuid }
    event
  end
end
