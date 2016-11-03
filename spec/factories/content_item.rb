FactoryGirl.define do
  factory :content_item do
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

    transient do
      lock_version 1
      state "draft"
      locale "en"
      sequence(:base_path) { |n| "/vat-rates-#{n}" }
      user_facing_version 1
      change_note "note"
    end

    after(:create) do |item, evaluator|
      FactoryGirl.create(:state, name: evaluator.state, content_item: item)
      FactoryGirl.create(:translation, locale: evaluator.locale, content_item: item)
      FactoryGirl.create(:lock_version, number: evaluator.lock_version, target: item)
      FactoryGirl.create(:user_facing_version, number: evaluator.user_facing_version, content_item: item)

      unless evaluator.base_path.nil?
        FactoryGirl.create(:location, base_path: evaluator.base_path, content_item: item)
      end
      unless item.update_type == 'minor'
        FactoryGirl.create(:change_note, note: evaluator.change_note, content_item: item)
      end
    end
  end

  factory :redirect_content_item, parent: :content_item do
    transient do
      destination "/somewhere"
    end
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name "redirect"
    document_type "redirect"
    routes []
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_content_item, parent: :content_item do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name "gone"
    document_type "gone"
  end
end
