FactoryGirl.define do
  factory :unpublished_content_item, parent: :content_item, aliases: [:gone_unpublished_content_item] do
    state "unpublished"
    content_store "live"
    transient do
      unpublishing_type "gone"
      explanation "Removed for testing reasons"
      alternative_path "/new-path"
      unpublished_at nil
    end

    after(:create) do |content_item, evaluator|
      FactoryGirl.create(:unpublishing,
        content_item: content_item,
        type: evaluator.unpublishing_type,
        explanation: evaluator.explanation,
        alternative_path: evaluator.alternative_path,
        unpublished_at: evaluator.unpublished_at,
      )
    end
  end

  factory :withdrawn_unpublished_content_item, parent: :unpublished_content_item do
    content_store 'live'
    transient do
      unpublishing_type "withdrawal"
      unpublished_at nil
    end
  end

  factory :redirect_unpublished_content_item, parent: :unpublished_content_item do
    content_store 'live'
    transient do
      unpublishing_type "redirect"
      unpublished_at nil
    end
  end

  factory :vanish_unpublished_content_item, parent: :unpublished_content_item do
    content_store 'live'
    transient do
      unpublishing_type "vanish"
      unpublished_at nil
    end
  end

  factory :substitute_unpublished_content_item, parent: :unpublished_content_item do
    content_store nil
    transient do
      unpublishing_type "substitute"
      unpublished_at nil
    end
  end
end
