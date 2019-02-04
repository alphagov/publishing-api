FactoryBot.define do
  factory :edition, aliases: [:draft_edition] do
    document
    title { "VAT rates" }
    description { "VAT rates for goods and services" }
    schema_name { "generic" }
    document_type { "services_and_information" }
    public_updated_at { "2014-05-14T13:00:06Z" }
    first_published_at { "2014-01-02T03:04:05Z" }
    last_edited_at { "2014-05-14T13:00:06Z" }
    published_at { nil }
    publishing_app { "publisher" }
    rendering_app { "frontend" }
    details { {} }
    phase { "beta" }
    update_type { "minor" }
    analytics_identifier { "GDS01" }
    routes do
      [
        {
          path: base_path,
          type: "exact",
        }
      ]
    end
    state { "draft" }
    content_store { "draft" }
    sequence(:base_path) { |n| "/vat-rates-#{n}" }
    user_facing_version { 1 }

    transient do
      change_note { "note" }
      links_hash { {} }
    end

    after(:create) do |item, evaluator|
      unless item.update_type == "minor" || evaluator.change_note.nil?
        create(
          :change_note,
          note: evaluator.change_note,
          edition: item,
        )
      end

      if evaluator.links_hash
        evaluator.links_hash.each do |link_type, target_content_ids|
          target_content_ids.each_with_index do |target_content_id, index|
            create(:link,
              edition: item,
              link_type: link_type,
              link_set: nil,
              position: index,
              target_content_id: target_content_id)
          end
        end
      end
    end
  end

  factory :redirect_edition, aliases: [:redirect_draft_edition], parent: :edition do
    transient do
      destination { "/somewhere" }
    end
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name { "redirect" }
    document_type { "redirect" }
    routes { [] }
    redirects { [{ 'path' => base_path, 'type' => 'exact', 'destination' => destination }] }
  end

  factory :gone_edition, aliases: [:gone_draft_edition], parent: :edition do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name { "gone" }
    document_type { "gone" }
    state { "superseded" }
    rendering_app { nil }
  end

  factory :access_limited_edition, aliases: [:access_limited_draft_edition], parent: :edition do
    sequence(:base_path) { |n| "/access-limited-#{n}" }

    after(:create) do |item, _|
      create(:access_limit, edition: item)
    end
  end

  factory :pathless_edition, aliases: [:pathless_draft_edition], parent: :edition do
    base_path { nil }
    schema_name { "contact" }
    document_type { "contact" }
  end
end
