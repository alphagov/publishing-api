require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.extend RequestHelpers
end

RSpec.describe "Content item live requests", :type => :request do
  include GOVUK::Client::TestHelpers::URLArbiter
  include MessageQueueHelpers

  def deep_stringify_keys(hash)
    JSON.parse(hash.to_json)
  end

  let(:base_path) {
    "/vat-rates"
  }

  let(:content_item) {
    {
      content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88",
      title: "VAT rates",
      description: "VAT rates for goods and services",
      format: "guide",
      need_ids: ["100123", "100124"],
      public_updated_at: "2014-05-14T13:00:06Z",
      publishing_app: "mainstream_publisher",
      rendering_app: "mainstream_frontend",
      locale: "en",
      phase: "beta",
      details: {
        body: "<p>Soemthing about VAT</p>\n",
      },
      routes: [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ],
      update_type: "major",
    }
  }

  let(:content_item_with_access_limiting) {
    content_item.merge(
      access_limited: {
        users: [
          "f17250b0-7540-0131-f036-005056030202",
          "74c7d700-5b4a-0131-7a8e-005056030037",
        ],
      },
    )
  }

  let(:stub_json_response) {
    double(:json_response, body: "", headers: {
      content_type: "application/json; charset=utf-8",
    })
  }

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, Plek.find('content-store') + "/content#{base_path}")
    stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}")
  end

  describe "PUT /content" do
    check_200_response
    check_400_on_invalid_json
    check_draft_content_store_502_suppression
    check_forwards_locale_extension
    check_accepts_root_path

    def put_content_item(body: content_item.to_json)
      put "/content#{base_path}", body
    end


    it "logs a 'PutContentWithLinks' event in the event log" do
      put_content_item
      expect(Event.count).to eq(1)
      expect(Event.first.action).to eq('PutContentWithLinks')
      expect(Event.first.user_uid).to eq(nil)
      expected_payload = deep_stringify_keys(content_item.merge("base_path" => base_path))
      expect(Event.first.payload).to eq(expected_payload)
    end

    it "creates the LiveContentItem derived representation" do
      put_content_item
      expect(LiveContentItem.count).to eq(1)
      item = LiveContentItem.first
      expect(item.base_path).to eq(base_path)
      expect(item.content_id).to eq(content_item[:content_id])
      expect(item.details).to eq(content_item[:details].deep_stringify_keys)
      expect(item.format).to eq(content_item[:format])
      expect(item.locale).to eq(content_item[:locale])
      expect(item.publishing_app).to eq(content_item[:publishing_app])
      expect(item.rendering_app).to eq(content_item[:rendering_app])
      expect(item.public_updated_at).to eq(content_item[:public_updated_at])
      expect(item.description).to eq(content_item[:description])
      expect(item.title).to eq(content_item[:title])
      expect(item.routes).to eq(content_item[:routes].map(&:deep_stringify_keys))
      expect(item.metadata["need_ids"]).to eq(content_item[:need_ids])
      expect(item.metadata["phase"]).to eq(content_item[:phase])
    end

    it "gives the LiveContentItem a version number of 1" do
      put_content_item
      expect(LiveContentItem.first.version).to eq(1)
    end

    context "a LiveContentItem already exists" do
      before {
        LiveContentItem.create(
          content_id: content_item[:content_id],
          locale: content_item[:locale],
          details: content_item[:details],
          metadata: {},
          base_path: base_path,
          version: 1
        )
      }

      it "updates it" do
        put_content_item
        expect(LiveContentItem.count).to eq(1)
      end

      it "increments the version number to 2" do
        put_content_item
        expect(LiveContentItem.first.version).to eq(2)
      end

      it "reports a validation error if attempting to change base_path" do
        put "/content/something-else", content_item.to_json
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to eq({"errors" => {"base_path" => "cannot change once item is live"}})
        expect(LiveContentItem.count).to eq(1)
        expect(LiveContentItem.first.base_path).to eq(base_path)
      end
    end

    it "creates the DraftContentItem derived representation" do
      put_content_item
      expect(DraftContentItem.count).to eq(1)
      item = DraftContentItem.first
      expect(item.base_path).to eq(base_path)
      expect(item.content_id).to eq(content_item[:content_id])
      expect(item.details).to eq(content_item[:details].deep_stringify_keys)
      expect(item.format).to eq(content_item[:format])
      expect(item.locale).to eq(content_item[:locale])
      expect(item.publishing_app).to eq(content_item[:publishing_app])
      expect(item.rendering_app).to eq(content_item[:rendering_app])
      expect(item.public_updated_at).to eq(content_item[:public_updated_at])
      expect(item.description).to eq(content_item[:description])
      expect(item.title).to eq(content_item[:title])
      expect(item.routes).to eq(content_item[:routes].map(&:deep_stringify_keys))
      expect(item.metadata["need_ids"]).to eq(content_item[:need_ids])
      expect(item.metadata["phase"]).to eq(content_item[:phase])
    end

    it "gives the DraftContentItem a version number of 1" do
      put_content_item
      expect(DraftContentItem.first.version).to eq(1)
    end

    context "a DraftContentItem already exists" do
      before {
        DraftContentItem.create(
          content_id: content_item[:content_id],
          locale: content_item[:locale],
          details: content_item[:details],
          metadata: {},
          version: 1
        )
      }

      it "updates it" do
        new_title = "My new title"
        put_content_item(body: content_item.merge(title: new_title).to_json)
        expect(DraftContentItem.count).to eq(1)
        item = DraftContentItem.first
        expect(item.title).to eq(new_title)
      end

      it "increments the version number to 2" do
        put_content_item
        expect(DraftContentItem.first.version).to eq(2)
      end
    end

    it "creates the Links derived representation" do
      put_content_item
      expect(Link.count).to eq(1)
    end

    it "gives the Links derived representation a version of 1" do
      put_content_item
      expect(Link.first.version).to eq(1)
    end

    context "a Link record already exists" do
      before { Link.create(content_id: content_item[:content_id], links: {}, version: 1) }

      it "updates it" do
        put_content_item
        expect(Link.count).to eq(1)
      end

      it "increments the version number to 2" do
        put_content_item
        expect(Link.first.version).to eq(2)
      end
    end

    context "content item without a content id" do
      let(:content_item) {
        {
          title: "VAT rates",
          description: "VAT rates for goods and services",
          format: "guide",
          need_ids: ["100123", "100124"],
          public_updated_at: "2014-05-14T13:00:06Z",
          publishing_app: "mainstream_publisher",
          rendering_app: "mainstream_frontend",
          locale: "en",
          phase: "beta",
          details: {
            body: "<p>Soemthing about VAT</p>\n",
          },
          routes: [
            {
              path: "/vat-rates",
              type: "exact",
            }
          ],
          update_type: "major",
        }
      }

      # TODO: alternately, we record derived representations and key them on base_path
      it "does not record any derived representations" do
        put_content_item
        expect(DraftContentItem.count).to eq(0)
        expect(LiveContentItem.count).to eq(0)
        expect(Link.count).to eq(0)
      end
    end

  end
end
