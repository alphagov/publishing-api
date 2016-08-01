FactoryGirl.define do
  factory :draft_content_item, parent: :content_item do
    transient do
      state "draft"
    end
  end

  factory :redirect_draft_content_item, parent: :draft_content_item do
    transient do
      destination "/somewhere"
    end
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name "redirect"
    document_type "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name "gone"
    document_type "gone"
  end

  factory :access_limited_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) { |n| "/access-limited-#{n}" }

    after(:create) do |item, _|
      FactoryGirl.create(:access_limit, content_item: item)
    end
  end

  factory :pathless_draft_content_item, parent: :draft_content_item do
    base_path nil
    schema_name "contact"
    document_type "contact"
  end
end
