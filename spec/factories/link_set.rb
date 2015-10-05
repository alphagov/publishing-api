FactoryGirl.define do
  factory :link_set do
    content_id { SecureRandom.uuid }
    version 1
    links {
      {
        organisations: [ SecureRandom.uuid ]
      }
    }
  end
end
