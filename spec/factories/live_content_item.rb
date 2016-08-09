FactoryGirl.define do
  factory :live_content_item, parent: :content_item do
    transient do
      draft_version_number 1
      state "published"
    end

    trait :with_draft do
      after(:create) do |live_content_item, evaluator|
        draft = FactoryGirl.create(:draft_content_item,
          live_content_item.as_json(only: %i[title content_id schema_name document_type routes redirects]).merge(
            locale: evaluator.locale,
            base_path: evaluator.base_path,
            lock_version: evaluator.lock_version,
          )
        )

        raise "Draft is not valid: #{draft.errors.full_messages}" unless draft.valid?
      end
    end

    trait :with_draft_version do
      with_draft
    end
  end

  factory :redirect_live_content_item, parent: :live_content_item do
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name "redirect"
    document_type "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => '/somewhere' }] }
  end

  factory :gone_live_content_item, parent: :live_content_item do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name "gone"
    document_type "gone"
  end

  factory :coming_soon_live_content_item, parent: :live_content_item do
    schema_name "coming_soon"
    document_type "coming_soon"
    title "Coming soon"
    description "This item will be published soon"
  end

  factory :pathless_live_content_item, parent: :live_content_item do
    base_path nil
    schema_name "contact"
    document_type "contact"
  end
end
