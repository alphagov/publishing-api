require "rails_helper"

RSpec.describe "Downstream requests", type: :request do
  let(:json_response) {
    double(:json_response, body: "", headers: {
      content_type: "application/json; charset=utf-8",
    })
  }

  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_body) { content_item.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    url_registration_happens
    url_registration_failures_422
    sends_to_draft_content_store

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(json_response)
        .ordered

      do_request
    end

    it "strips access limiting metadata from the document" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )

      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(json_response)

      do_request(body: content_item_with_access_limiting.to_json)
    end
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_body) { content_item.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    url_registration_happens
    url_registration_failures_422
    sends_to_draft_content_store
    does_not_send_to_live_content_store

    it "leaves access limiting metadata in the document" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(json_response)

      do_request(body: content_item.to_json)
    end
  end

  context "/v2/content" do
    let(:content_item) { v2_content_item }
    let(:request_body) { content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    url_registration_happens
    url_registration_failures_422
    sends_to_draft_content_store
    does_not_send_to_live_content_store

    it "leaves access limiting metadata in the document" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(json_response)

      do_request(body: content_item.to_json)
    end

    context "when a link set exists for the content item" do
      it "includes links in the payload sent to draft content store" do
        link_set = create(:link_set, content_id: content_item[:content_id])
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item.merge(links: link_set.links),
          )
          .and_return(json_response)

        do_request(body: content_item.to_json)
      end
    end

    context "when a link set does not exist for the content item" do
      it "sends the payload without links to the draft content store" do
        expect(LinkSet.count).to eq(0)
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item
          )
          .and_return(json_response)
        do_request(body: content_item.to_json)
      end
    end
  end

  context "/v2/links" do
    let(:content_item) {
      v2_content_item.merge(
        links: links_attributes[:links],
        update_type: "links",
      )
    }
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    context "when only a draft content item exists for the link set" do
      before do
        FactoryGirl.create(:draft_content_item, v2_content_item.slice(*DraftContentItem::TOP_LEVEL_FIELDS))
      end

      sends_to_draft_content_store(with_arbitration: false)
      does_not_send_to_live_content_store
    end

    context "when draft and live content items exists for the link set" do
      before do
        FactoryGirl.create(:draft_content_item, v2_content_item.slice(*DraftContentItem::TOP_LEVEL_FIELDS))
        FactoryGirl.create(:live_content_item, v2_content_item.slice(*LiveContentItem::TOP_LEVEL_FIELDS))
      end

      sends_to_draft_content_store(with_arbitration: false)
      sends_to_live_content_store
    end

    context "when a content item does not exist for the link set" do
      does_not_send_to_draft_content_store
      does_not_send_to_live_content_store
    end
  end
end
