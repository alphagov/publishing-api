FactoryGirl.define do
  factory :access_limit do
    users { [SecureRandom.uuid] }
  end
end
