FactoryGirl.define do
  factory :content_item_link do
    source    { SecureRandom.uuid }
    link_type { "organisations" }
    target    { SecureRandom.uuid }
  end
end
