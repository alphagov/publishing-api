FactoryGirl.define do
  factory :content_store_payload_version do
    content_item_id 1
  end

  factory :v1_content_store_payload_version, parent: :content_store_payload_version do
    content_item_id nil
  end
end
