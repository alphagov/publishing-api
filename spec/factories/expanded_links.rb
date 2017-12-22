FactoryBot.define do
  factory :expanded_links do
    content_id { SecureRandom.uuid }
    locale { "en" }
    with_drafts { false }
  end
end
