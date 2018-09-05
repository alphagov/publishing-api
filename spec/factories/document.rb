FactoryBot.define do
  factory :document do
    content_id { SecureRandom.uuid }
    locale { "en" }
    stale_lock_version { 1 }
  end
end
