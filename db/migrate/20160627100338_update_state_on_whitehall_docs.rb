class UpdateStateOnWhitehallDocs < ActiveRecord::Migration
  def up
    # These are all currently in a 'draft' state. This is at odds with the
    # state of these documents in Whitehall, where the slugs below represent
    # published content.
    doc_fixes = [
      {
        base_path: "/guidance/how-to-appeal-your-rateable-value",
        content_id: "e76c9e81-9fce-48e5-8ccb-100fe77ac14c",
      },
      {
        base_path: "/government/news/cma-opens-consultation-on-reed-elsevier-undertakings",
        content_id: "cda4858b-6de1-4911-9009-19d4838128f6",
      },
      {
        base_path: "/government/collections/common-land-guidance-for-commons-registration-authorities-and-applicants",
        content_id: "9f5d498b-849d-4b67-b6c2-6624105d4bb3",
      },
      {
        base_path: "/government/news/rpa-remains-on-track-to-pay-bps-2015-claims-from-december",
        content_id: "744a3fb2-6a64-4a9f-a709-a79f5dbb3252",
      },
      {
        base_path: "/government/world-location-news/uk-visa-operations-in-south-india-are-impacted-by-the-floods-in-chennai",
        content_id: "4be55cf7-316b-4961-a293-05ebdd786c78",
      },
    ]

    for_updating = ContentItem.where(content_id: doc_fixes.map { |doc| doc[:content_id] })
    for_updating.each do |content_item|
      Commands::V2::Publish.call(content_id: content_item.content_id, update_type: 'minor')
    end
  end
end
