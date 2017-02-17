FactoryGirl.define do
  factory :unpublishing do
    edition
    type "gone"
    explanation "Removed for testing reasons"
    alternative_path "/new-path"
    redirects [{ path: "/new-path", type: "exact" }]
  end
end
