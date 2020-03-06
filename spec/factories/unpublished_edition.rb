FactoryBot.define do
  factory :unpublished_edition, parent: :edition, aliases: [:gone_unpublished_edition] do
    state { "unpublished" }
    content_store { "live" }
    public_updated_at { "2014-05-14T13:00:06Z" }
    first_published_at { "2014-01-02T03:04:05Z" }
    transient do
      unpublishing_type { "gone" }
      explanation { "Removed for testing reasons" }
      alternative_path { "/new-path" }
      unpublished_at { "2014-01-02T03:04:05Z" }
    end

    after(:create) do |edition, evaluator|
      create(:unpublishing,
             edition: edition,
             type: evaluator.unpublishing_type,
             explanation: evaluator.explanation,
             redirects: [{ path: edition.base_path, type: :exact, destination: evaluator.alternative_path }],
             unpublished_at: evaluator.unpublished_at)
    end
  end

  factory :withdrawn_unpublished_edition, parent: :unpublished_edition do
    content_store { "live" }
    transient do
      unpublishing_type { "withdrawal" }
      unpublished_at { nil }
    end
  end

  factory :redirect_unpublished_edition, parent: :unpublished_edition do
    content_store { "live" }
    transient do
      unpublishing_type { "redirect" }
      unpublished_at { nil }
    end
  end

  factory :vanish_unpublished_edition, parent: :unpublished_edition do
    content_store { "live" }
    transient do
      unpublishing_type { "vanish" }
      unpublished_at { nil }
    end
  end

  factory :substitute_unpublished_edition, parent: :unpublished_edition do
    content_store { nil }
    transient do
      unpublishing_type { "substitute" }
      unpublished_at { nil }
    end
  end
end
