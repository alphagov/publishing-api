FactoryBot.define do
  factory :access_limit do
    users { [SecureRandom.uuid] }
    organisations { [SecureRandom.uuid] }
    edition
  end
end
