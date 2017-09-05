FactoryGirl.define do
  factory :link_change do
    source_content_id { SecureRandom.uuid }
    target_content_id { SecureRandom.uuid }
    action
    link_type "taxons"
    change 1
  end
end
