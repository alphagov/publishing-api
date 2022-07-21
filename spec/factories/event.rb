FactoryBot.define do
  factory :event do
    transient do
      title { "An exciting piece of content" }
    end
    action { "PutContent" }
    content_id { SecureRandom.uuid }
    user_uid { SecureRandom.uuid }
    request_id do
      "#{rand(1000..9999)}-#{Time.zone.now.to_f.round(3)}-127.0.0.1-#{rand(1000..9999)}"
    end
    updated_at { created_at }
    payload do
      {
        content_id:,
        locale: "en",
        title:,
      }
    end
  end
end
