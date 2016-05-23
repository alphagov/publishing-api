FactoryGirl.define do
  factory :linkable do
    content_item
    base_path "/vat-rates"
    state "draft"
    document_type "policy"
  end
end
