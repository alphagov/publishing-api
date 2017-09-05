require "rails_helper"

RSpec.describe "Keeping track of link changes", type: :request do
  scenario "No links are added" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      {}
    )

    when_i_request_link_changes

    expect(parsed_response["link_changes"]).to eql([])
  end

  scenario "A link is added" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: ["1f0b3601-6a1d-4065-adc6-bf6040e2a806"]
    )

    when_i_request_link_changes

    expect(parsed_response["link_changes"].size).to eql(1)
  end

  scenario "A link is changed" do
    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: ["1f0b3601-6a1d-4065-adc6-bf6040e2a806"]
    )

    make_patch_links_request(
      "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
      something: ["0bbd6b21-b6f4-4327-aa40-696bda836000"]
    )

    when_i_request_link_changes

    expect(parsed_response["link_changes"].size).to eql(3)
  end

  scenario "Fetching the link actions" do
    4.times {
      make_patch_links_request(
        "2ee935c3-d926-4737-aa23-e8c5edb5c3ca",
        something: [SecureRandom.uuid]
      )
    }

    get "/v2/links/changes?start=#{LinkChange.last.id}"

    expect(parsed_response["link_changes"].size).to eql(1)
  end

  describe "Paging through the actions" do
    it "supplies the next page" do
      3.times {
        make_patch_links_request(
          "31f8cfad-6804-40f9-8124-8725c45a8371",
          something: [SecureRandom.uuid]
        )
      }

      # Dirty trick to limit pagination
      stub_const("Queries::GetLinkChanges::PAGE_LENGTH", 2)

      when_i_request_link_changes

      expect(parsed_response["link_changes"].length).to eq(2)
      expect(parsed_response["link_changes"].first["id"]).to eq(LinkChange.first.id)

      get parsed_response["next_page_path"]

      expect(parsed_response["link_changes"].length).to eq(2)

      get parsed_response["next_page_path"]

      expect(parsed_response["link_changes"].length).to eq(1)
      expect(parsed_response["link_changes"].last["id"]).to eq(LinkChange.last.id)
      expect(parsed_response["next_page_path"]).to be_nil
    end
  end

  def when_i_request_link_changes
    get "/v2/links/changes"
  end

  def make_patch_links_request(content_id, links)
    patch "/v2/links/#{content_id}",
          params: { links: links }.to_json,
          headers: { "X-GOVUK-AUTHENTICATED-USER" => SecureRandom.uuid }
  end
end
