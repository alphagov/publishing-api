FactoryGirl.define do
  factory :unpublishing do
    content_item
    type "gone"
    explanation "Removed for testing reasons"
    alternative_url "http://example.com/unpublishing"
  end
end
