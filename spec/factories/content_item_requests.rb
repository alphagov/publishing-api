FactoryBot.define do
  factory :content_item_request_data, class: Hash do
    content_id { SecureRandom.uuid }
    sequence(:base_path) { |n| "/test-content-#{n}" }
    title { "Test content" }
    description { "Test description" }
    document_type { "answer" }
    schema_name { "answer" }
    public_updated_at { Time.now.utc.iso8601 }
    publishing_app { "publisher" }
    rendering_app { "frontend" }
    locale { "en" }
    phase { "live" }
    details { { "body" => "<p>Something something</p>\n" } }
    routes do
      [{ "path" => base_path, "type" => "exact" }]
    end
    redirects { [] }
    update_type { "major" }

    skip_create

    trait :access_limited do
      access_limited { { "users" => %w[3fa46076-2dfd-4169-bcb0-141e2e4bc9b0] } }
    end
  end
end
