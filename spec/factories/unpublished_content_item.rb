FactoryGirl.define do
  factory :unpublished_content_item, parent: :content_item do
    transient do
      state "unpublished"
      unpublishing_type "gone"
      explanation "Removed for testing reasons"
      alternative_path "/new-path"
    end

    after(:create) do |content_item, evaluator|
      FactoryGirl.create(:unpublishing,
        content_item: content_item,
        type: evaluator.unpublishing_type,
        explanation: evaluator.explanation,
        alternative_path: evaluator.alternative_path,
      )
    end
  end
end
