FactoryGirl.define do
  factory :draft_web_content_item, class: WebContentItem do
    content_id { SecureRandom.uuid }
    title "VAT rates"
    description "VAT rates for goods and services"
    schema_name "guide"
    document_type "guide"
    public_updated_at "2014-05-14T13:00:06Z"
    first_published_at "2014-01-02T03:04:05Z"
    last_edited_at "2014-05-14T13:00:06Z"
    publishing_app "publisher"
    rendering_app "frontend"
    details {
      { body: "<p>Something about VAT</p>\n", }
    }
    need_ids %w(100123 100124)
    phase "beta"
    update_type "minor"
    analytics_identifier "GDS01"
    routes {
      [
        {
          path: base_path,
          type: "exact",
        }
      ]
    }
    redirects []
    state "draft"
    locale "en"
    sequence(:base_path) { |n| "/vat-rates-#{n}" }
    user_facing_version 1
  end

  trait :live do
    state "published"
  end

  factory :live_web_content_item, parent: :draft_web_content_item, traits: [:live]

  factory :gone_draft_web_content_item, parent: :draft_web_content_item do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name "gone"
    document_type "gone"
  end
end
