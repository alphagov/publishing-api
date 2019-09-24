require "rails_helper"

RSpec.describe "Keeping track of link changes", type: :request do
  scenario "No links are added or changed" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      {}
    )

    expect(LinkChange.count).to eql(0)
  end

  scenario "A link is added" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: %w[1f0b3601-6a1d-4065-adc6-bf6040e2a806],
    )

    expect(LinkChange.count).to eql(1)

    expect(
      LinkChange.last.as_json(only: %w[target_content_id source_content_id link_type change]),
    ).to eql(
      "source_content_id" => "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      "target_content_id" => "1f0b3601-6a1d-4065-adc6-bf6040e2a806",
      "link_type" => "something",
      "change" => "add",
    )
  end

  scenario "A link is changed" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: %w[1f0b3601-6a1d-4065-adc6-bf6040e2a806],
    )

    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: %w[0bbd6b21-b6f4-4327-aa40-696bda836000],
    )

    expect(LinkChange.count).to eql(3)
  end

  def make_patch_links_request(content_id, links)
    patch "/v2/links/#{content_id}",
          params: { links: links }.to_json,
          headers: { "X-GOVUK-AUTHENTICATED-USER" => SecureRandom.uuid }
  end
end
