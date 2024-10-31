FactoryBot.define do
  factory :statistics_cache do
    document { create(:document) }
    unique_pageviews { 123 }
  end
end
