FactoryGirl.define do
  factory :unpublishing do
    content_item
    type "gone"
    explanation "Removed for testing reasons"
    alternative_path "/new-path"
  end
end
