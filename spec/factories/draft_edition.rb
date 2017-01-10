FactoryGirl.define do
  factory :draft_edition, parent: :edition do
    state "draft"
    content_store "draft"
  end

  factory :redirect_draft_edition, parent: :draft_edition do
    transient do
      destination "/somewhere"
    end
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name "redirect"
    document_type "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_draft_edition, parent: :draft_edition do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name "gone"
    document_type "gone"
  end

  factory :access_limited_draft_edition, parent: :draft_edition do
    sequence(:base_path) { |n| "/access-limited-#{n}" }

    after(:create) do |item, _|
      FactoryGirl.create(:access_limit, edition: item)
    end
  end

  factory :pathless_draft_edition, parent: :draft_edition do
    base_path nil
    schema_name "contact"
    document_type "contact"
  end
end
