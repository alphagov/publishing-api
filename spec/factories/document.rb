FactoryGirl.define do
  factory :document do
    content_id { SecureRandom.uuid }
    locale "en"
  end
end
