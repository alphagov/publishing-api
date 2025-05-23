FactoryBot.define do
  factory :live_edition, parent: :edition do
    user_facing_version { 1 }
    state { "published" }
    content_store { "live" }
    public_updated_at { "2014-05-14T13:00:06Z" }
    first_published_at { "2014-01-02T03:04:05Z" }
    last_edited_by_editor_id { SecureRandom.uuid }

    transient do
      draft_version_number { 2 }
    end

    trait :with_draft do
      after(:create) do |live_edition, evaluator|
        draft = create(
          :draft_edition,
          live_edition.as_json(only: %i[title document_id schema_name document_type routes redirects]).merge(
            base_path: evaluator.base_path,
            user_facing_version: evaluator.draft_version_number,
          ),
        )

        raise "Draft is not valid: #{draft.errors.full_messages}" unless draft.valid?
      end
    end

    trait :with_draft_version do
      with_draft
    end

    trait :with_embedded_content do
      base_path { "/#{SecureRandom.uuid}" }
      details { { body: "{{embed:#{embedded_content_type}:#{embedded_content_id}" } }

      transient do
        embedded_content_id { SecureRandom.uuid }
        embedded_content_type { "content_block_pension" }
        links_hash { { embed: [embedded_content_id] } }
      end
    end

    after(:create) do |live_edition, evaluator|
      unless evaluator.published_at
        live_edition.update!(published_at: live_edition.created_at)
      end
    end
  end

  factory :redirect_live_edition, parent: :live_edition do
    sequence(:base_path) { |n| "/test-redirect-#{n}" }
    schema_name { "redirect" }
    document_type { "redirect" }
    routes { [] }
    redirects { [{ "path" => base_path, "type" => "exact", "destination" => "/somewhere" }] }
  end

  factory :gone_live_edition, parent: :live_edition do
    sequence(:base_path) { |n| "/dodo-sanctuary-#{n}" }
    schema_name { "gone" }
    document_type { "gone" }
  end

  factory :coming_soon_live_edition, parent: :live_edition do
    schema_name { "coming_soon" }
    document_type { "coming_soon" }
    title { "Coming soon" }
    description { "This item will be published soon" }
  end

  factory :pathless_live_edition, parent: :live_edition do
    base_path { nil }
    schema_name { "contact" }
    document_type { "contact" }
  end
end
