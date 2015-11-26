FactoryGirl.define do
  factory :link_set do
    content_id { SecureRandom.uuid }
  end
end
