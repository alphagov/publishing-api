FactoryGirl.define do
  factory :draft_content_item do
    content_id { SecureRandom.uuid }
    base_path do
      suffix = ".#{locale}" unless locale == "en"
      "/vat-rates#{suffix}"
    end
    title "VAT rates"
    description "VAT rates for goods and services"
    format "guide"
    public_updated_at "2014-05-14T13:00:06Z"
    publishing_app "publisher"
    rendering_app "frontend"
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

    trait :with_version do
      after(:create) do |item, _|
        FactoryGirl.create(:version, target: item)
      end
    end
  end

  factory :redirect_draft_content_item, parent: :draft_content_item do
    transient do
      destination "/somewhere"
    end
    sequence(:base_path) {|n| "/test-redirect-#{n}" }
    format "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) {|n| "/dodo-sanctuary-#{n}" }
    format "gone"
  end

  factory :access_limited_draft_content_item, parent: :draft_content_item do
    sequence(:base_path) {|n| "/access-limited-#{n}" }

    after(:create) do |item, _|
      FactoryGirl.create(:access_limit, target: item)
    end
  end
end
