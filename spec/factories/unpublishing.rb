FactoryBot.define do
  factory :unpublishing do
    edition
    type { "gone" }
    explanation { "Removed for testing reasons" }
    alternative_path { "/new-path" }

    after(:build) do |unpublishing|
      if unpublishing.redirect? && !unpublishing.redirects
        unpublishing.redirects = [
          {
            path: unpublishing.edition.base_path,
            type: :exact,
            destination: unpublishing.alternative_path,
          },
        ]
      end
    end
  end
end
