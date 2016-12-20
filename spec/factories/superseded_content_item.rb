FactoryGirl.define do
  factory :superseded_content_item, parent: :live_content_item do
    content_store nil
    state "superseded"
  end
end
