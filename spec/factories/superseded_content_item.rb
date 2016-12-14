FactoryGirl.define do
  factory :superseded_content_item, parent: :live_content_item do
    state "superseded"
    content_store nil
  end
end
