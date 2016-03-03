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
    format "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    format "gone"
  end

  factory :access_limited_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) { |n| "/access-limited-#{n}" }

    after(:create) do |item, _|
      FactoryGirl.create(:access_limit, content_item: item)
    end
  end
end
