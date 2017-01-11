FactoryGirl.define do
  factory :content_item do
    document { FactoryGirl.create(:document) }
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
    state "draft"
    content_store "draft"
    sequence(:base_path) { |n| "/vat-rates-#{n}" }
    user_facing_version 1

    transient do
      lock_version nil
      change_note "note"
    end

    after(:create) do |item, evaluator|
      unless evaluator.lock_version.nil?
        item.document.update! stale_lock_version: evaluator.lock_version
      end

      unless item.update_type == "minor" || evaluator.change_note.nil?
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
