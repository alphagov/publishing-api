namespace :protected_food_drink_name do
  desc "Republishes protected food and drink name editions with updated details"
  task update_registered_details: :environment do
    content_ids = []

    Edition
      .where(document_type: "protected_food_drink_name")
      .where("details -> 'metadata' ->> 'register' IN(?)", %w[wines traditional-terms-for-wine])
      .where("details -> 'metadata' ->> 'reason_for_protection' IN(?)", %w[uk-gi-before-2021 eu-agreement])
      .where("details -> 'metadata' ->> 'status' = ?", "registered")
      .each do |edition|
        edition.details = edition.details.deep_merge({
          metadata: {
            date_registration: "2021-03-10",
            time_registration: nil,
          },
        })
        edition.save!
        content_ids << edition.content_id
      end

    Rake::Task["represent_downstream:content_id"].invoke(content_ids)
  end
end
