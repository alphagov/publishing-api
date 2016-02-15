FactoryGirl.define do
  factory :content_item do
    content_id { SecureRandom.uuid }
    title "VAT rates"
    description "VAT rates for goods and services"
    format "guide"
    public_updated_at "2014-05-14T13:00:06Z"
    publishing_app "publisher"
    rendering_app "frontend"
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

    transient do
      locale "en"
      state "draft"
      base_path "/vat-rates"
      user_facing_version 1
      lock_version 0
    end

    trait :with_lock_version do
      after(:create) do |item, evaluator|
        FactoryGirl.create(:lock_version, number: evaluator.lock_version, target: item)
      end
    end

    trait :with_state do
      after(:create) do |item, evaluator|
        FactoryGirl.create(:state, name: evaluator.state, content_item: item)
      end
    end

    trait :with_translation do
      after(:create) do |item, evaluator|
        FactoryGirl.create(:translation, locale: evaluator.locale, content_item: item)
      end
    end

    trait :with_location do
      after(:create) do |item, evaluator|
        FactoryGirl.create(:location, base_path: evaluator.base_path, content_item: item)
      end
    end

    trait :with_user_facing_version do
      after(:create) do |item, evaluator|
        FactoryGirl.create(:user_facing_version, number: evaluator.user_facing_version, content_item: item)
      end
    end
  end

  factory :redirect_content_item, parent: :content_item do
    transient do
      destination "/somewhere"
    end
    sequence(:base_path) {|n| "/test-redirect-#{n}" }
    format "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_content_item, parent: :content_item do
    sequence(:base_path) {|n| "/dodo-sanctuary-#{n}" }
    format "gone"
  end
end
