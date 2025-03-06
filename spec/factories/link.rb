FactoryBot.define do
  factory :link do
    link_set          { create(:link_set) unless edition }
    target_content_id { SecureRandom.uuid }
    link_type         { "organisations" }
  end
end
