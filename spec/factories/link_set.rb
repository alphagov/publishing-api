FactoryBot.define do
  factory :link_set do
    content_id { SecureRandom.uuid }

    transient do
      links_hash { {} }
    end

    after(:create) do |link_set, evaluator|
      evaluator.links_hash.each do |link_type, target_content_ids|
        target_content_ids.each_with_index do |target_content_id, index|
          create(:link,
            link_type: link_type,
            link_set: link_set,
            target_content_id: target_content_id,
            position: index)
        end
      end
    end
  end
end
