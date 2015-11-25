FactoryGirl.define do
  factory :live_content_item do |args|
    content_id { SecureRandom.uuid }
    base_path "/vat-rates"
    title "VAT rates"
    description "VAT rates for goods and services"
    format "guide"
    public_updated_at "2014-05-14T13:00:06Z"
    publishing_app "mainstream_publisher"
    rendering_app "mainstream_frontend"
    locale "en"
    details {
      { body: "<p>Something about VAT</p>\n", }
    }
    need_ids ["100123", "100124"]
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

    trait :with_draft do
      after(:build) do |live_content_item, evaluator|
        draft = FactoryGirl.build(
          :draft_content_item,
          live_content_item.as_json(only: %i[content_id locale base_path format routes redirects]),
        )

        raise "Draft is not valid: #{draft.errors.full_messages}" unless draft.valid?

        live_content_item.draft_content_item = draft
      end
    end
  end

  factory :redirect_live_content_item, parent: :live_content_item do
    sequence(:base_path) {|n| "/test-redirect-#{n}" }
    format "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => '/somewhere' }] }
  end

  factory :gone_live_content_item, parent: :live_content_item do
    sequence(:base_path) {|n| "/dodo-sanctuary-#{n}" }
    format "gone"
  end
end
