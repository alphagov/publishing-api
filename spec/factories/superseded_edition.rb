FactoryBot.define do
  factory :superseded_edition, parent: :live_edition do
    content_store { nil }
    state { "superseded" }
  end
end
