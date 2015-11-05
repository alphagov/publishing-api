FactoryGirl.define do
  factory :link_set do
    content_id { SecureRandom.uuid }
    links {
      {
        organisations: [ SecureRandom.uuid ]
      }
    }
  end
end
