RSpec.describe "Requesting draft content by base path" do
  context "when not all content is available as a draft" do
    it "will link from live editions to draft editions and vice versa" do
      level_2_target_edition = create(:live_edition, title: "level 2 edition 1, live")

      level_1_target_document = create(:document)
      create(
        :live_edition,
        title: "level 1 edition 1, live",
        document: level_1_target_document,
      )
      create(
        :draft_edition,
        title: "level 1 edition 2, draft",
        document: level_1_target_document,
        link_set_links: [
          { link_type: "parent_taxons", target_content_id: level_2_target_edition.content_id },
        ],
      )

      edition = create(
        :live_edition,
        title: "root edition, live",
        edition_links: [
          { link_type: "taxons", target_content_id: level_1_target_document.content_id },
        ],
      )

      get "/graphql/draft/#{edition.base_path}"

      parsed_response = JSON.parse(response.body)

      expect(parsed_response).to match(
        a_hash_including("title" => "root edition, live"),
      )
      expect(parsed_response["links"]).to match(
        a_hash_including(
          "taxons" => match_array(
            a_hash_including("title" => "level 1 edition 2, draft"),
          ),
        ),
      )
      expect(parsed_response["links"]["taxons"].first["links"]).to match(
        a_hash_including(
          "parent_taxons" => match_array(
            a_hash_including("title" => "level 2 edition 1, live"),
          ),
        ),
      )
    end
  end
end
