FactoryGirl.define do
  factory :live_content_item do
    content_id { SecureRandom.uuid }
    base_path "/vat-rates"
    title "VAT rates"
    description "VAT rates for goods and services"
    format "guide"
    public_updated_at "2014-05-14T13:00:06Z"
    publishing_app "mainstream_publisher"
    rendering_app "mainstream_frontend"
    locale "en"
    version 1
    details {
      { body: "<p>Something about VAT</p>\n", }
    }
    metadata {
      {
        need_ids: ["100123", "100124"],
        phase: "beta",
      }
    }
    routes {
      [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ]
    }
    redirects {
      [
        {
          path: "/old-vat-rates",
          type: "exact",
          destination: "/vat-rates",
        }
      ]
    }
    after(:build) do |live_content_item|
      draft = FactoryGirl.build(
        :draft_content_item,
        content_id: live_content_item.content_id
      )

      live_content_item.draft_content_item = draft
    end
  end
end
