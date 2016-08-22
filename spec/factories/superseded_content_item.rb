FactoryGirl.define do
  factory :superseded_content_item, parent: :live_content_item do
    state "superseded"
  end
end
