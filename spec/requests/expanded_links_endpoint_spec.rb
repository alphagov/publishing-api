require "rails_helper"

RSpec.describe "GET /v2/expanded-links/:id", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:updated_at) { Time.zone.local("2017-07-27 16:44:00") }

  context "when requested without a locale" do
    let(:expanded_links) do
      {
        organisations: [{ content_id: SecureRandom.uuid }],
        available_translations: [{ content_id: content_id }],
      }
    end

    before do
      create(:expanded_links,
             content_id: content_id,
             locale: "en",
             with_drafts: true,
             expanded_links: expanded_links,
             updated_at: updated_at)
    end

    it "is assumed to be 'en'" do
      get "/v2/expanded-links/#{content_id}"

      expect(parsed_response).to eql(
        "generated" => updated_at.utc.iso8601,
        "expanded_links" => expanded_links.as_json,
      )
    end
  end

  context "when requesting a different locale" do
    let(:expanded_links) do
      {
        german_organisations: [{ content_id: SecureRandom.uuid }],
        available_translations: [{ content_id: content_id }],
      }
    end

    before do
      create(:expanded_links,
             content_id: content_id,
             locale: "de",
             with_drafts: true,
             expanded_links: expanded_links,
             updated_at: updated_at)
    end

    it "returns the links for that locale" do
      get "/v2/expanded-links/#{content_id}", params: { locale: "de" }

      expect(parsed_response).to eql(
        "generated" => updated_at.utc.iso8601,
        "expanded_links" => expanded_links.as_json,
      )
    end
  end

  context "when requesting a content_id that isn't known" do
    it "returns 404" do
      get "/v2/expanded-links/#{content_id}"

      expect(parsed_response).to eql(
        "error" => {
          "code" => 404,
          "message" => "Could not find links for content_id: #{content_id}",
        },
      )
    end
  end

  context "when request specifies to exclude drafts" do
    let(:expanded_links) do
      {
        non_draft_organisations: [{ content_id: SecureRandom.uuid }],
        available_translations: [{ content_id: content_id }],
      }
    end

    before do
      create(:expanded_links,
             content_id: content_id,
             locale: "en",
             with_drafts: false,
             expanded_links: expanded_links,
             updated_at: updated_at)
    end

    it "it returns the links " do
      get "/v2/expanded-links/#{content_id}", params: { with_drafts: false }

      expect(parsed_response).to eql(
        "generated" => updated_at.utc.iso8601,
        "expanded_links" => expanded_links.as_json,
      )
    end
  end

  context "when specifying to generate the links" do
    let(:linked_content_id) { SecureRandom.uuid }

    let!(:edition) do
      create(:live_edition,
             document: create(:document, content_id: content_id),
             base_path: "/some-path",
             links_hash: { organisations: [linked_content_id] })
    end

    let!(:linked_edition) do
      create(:live_edition,
             document: create(:document, content_id: linked_content_id),
             base_path: "/another-path")
    end

    let(:expanded_links) do
      {
        "organisations" => [
          a_hash_including(
            "content_id" => linked_content_id,
            "base_path" => "/another-path",
          ),
        ],
        "available_translations" => [
          a_hash_including(
            "content_id" => content_id,
            "base_path" => "/some-path",
          ),
        ],
      }
    end

    it "generates the links at runtime" do
      Timecop.freeze do
        get "/v2/expanded-links/#{content_id}", params: { generate: true }

        expect(parsed_response).to match(
          "generated" => Time.now.utc.iso8601,
          "expanded_links" => expanded_links,
          "version" => 0,
        )
      end
    end
  end
end
