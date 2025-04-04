FactoryBot.define do
  factory :link do
    link_set          { create(:link_set) unless edition }
    target_content_id { SecureRandom.uuid }
    link_type         { "organisations" }

    # TODO: ADR-009 - remove when we remove link_set_id
    after(:build) do |link,|
      if link.link_set.present?
        link.link_set_id = link.link_set.attributes["id"]
      end
    end
  end
end
