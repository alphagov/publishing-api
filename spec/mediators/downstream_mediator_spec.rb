require "rails_helper"

RSpec.describe DownstreamMediator do
  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    stub_request(:delete, %r{.*content-store.*/content/.*})
  end

  def create_web_content_item(factory, factory_options = {})
    content_item = FactoryGirl.create(factory, factory_options)
    Queries::GetWebContentItems.find(content_item.id)
  end

  let(:live_web_content_item) {
    create_web_content_item(:live_content_item, base_path: base_path)
  }
  let(:pathless_live_web_content_item) {
    create_web_content_item(:pathless_live_content_item)
  }
  let(:draft_web_content_item) {
    create_web_content_item(:draft_content_item, base_path: base_path)
  }
  let(:pathless_draft_web_content_item) {
    create_web_content_item(:pathless_draft_content_item)
  }
  let(:withdrawn_unpublished_web_content_item) {
    create_web_content_item(:withdrawn_unpublished_content_item, base_path: base_path)
  }
  let(:redirect_unpublished_web_content_item) {
    create_web_content_item(:redirect_unpublished_content_item, base_path: base_path)
  }
  let(:gone_unpublished_web_content_item) {
    create_web_content_item(:gone_unpublished_content_item, base_path: base_path)
  }
  let(:vanish_unpublished_web_content_item) {
    create_web_content_item(:vanish_unpublished_content_item, base_path: base_path)
  }
  let(:substitute_unpublished_web_content_item) {
    create_web_content_item(:substitute_unpublished_content_item, base_path: base_path)
  }

  let(:base_path) { "/vat-rates" }
  let(:payload_version) { 1 }
  let(:live_content_store) { Adapters::ContentStore }
  let(:draft_content_store) { Adapters::DraftContentStore }

  describe "#send_to_live_content_store" do
    context "published content item" do
      context "has base_path" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: live_web_content_item,
            payload_version: payload_version,
          )
        }

        it "is sends to live content store" do
          expect(live_content_store).to receive(:put_content_item)
            .with(
              base_path,
              a_hash_including(:content_id, :payload_version)
            )
          mediator.send_to_live_content_store
        end
      end

      context "no base_path" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: pathless_live_web_content_item,
            payload_version: payload_version,
          )
        }

        it "raises a DownstreamInvariantError" do
          expect {
            mediator.send_to_live_content_store
          }.to raise_error(DownstreamInvariantError)
        end
      end
    end

    context "unpublished content item" do
      context "withdrawal" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: withdrawn_unpublished_web_content_item,
            payload_version: payload_version,
          )
        }

        it "sends to live content store" do
          expected_hash = a_hash_including(
            :content_id,
            :payload_version,
            withdrawn_notice: a_hash_including(:explanation),
          )

          expect(live_content_store).to receive(:put_content_item)
            .with(base_path, expected_hash)
          mediator.send_to_live_content_store
        end
      end

      context "redirect" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: redirect_unpublished_web_content_item,
            payload_version: payload_version,
          )
        }

        it "sends to live content store" do
          expected_hash = a_hash_including(
            :payload_version,
            document_type: "redirect",
          )

          expect(live_content_store).to receive(:put_content_item)
            .with(base_path, expected_hash)
          mediator.send_to_live_content_store
        end
      end

      context "gone" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: gone_unpublished_web_content_item,
            payload_version: payload_version,
          )
        }

        it "sends to live content store" do
          expected_hash = a_hash_including(
            :payload_version,
            document_type: "gone",
            details: a_hash_including(:explanation)
          )

          expect(live_content_store).to receive(:put_content_item)
            .with(base_path, expected_hash)
          mediator.send_to_live_content_store
        end
      end

      context "vanish" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: vanish_unpublished_web_content_item,
            payload_version: payload_version,
          )
        }

        it "deletes from live content store" do
          expect(live_content_store).to receive(:delete_content_item)
            .with(base_path)
          mediator.send_to_live_content_store
        end
      end

      context "substitute" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: substitute_unpublished_web_content_item,
            payload_version: payload_version,
          )
        }

        it "doesnt interact with live content store" do
          expect(live_content_store).to_not receive(:put_content_item)
          expect(live_content_store).to_not receive(:delete_content_item)
          mediator.send_to_live_content_store
        end
      end
    end

    context "draft content item" do
      subject(:mediator) {
        DownstreamMediator.new(
          web_content_item: draft_web_content_item,
          payload_version: payload_version,
        )
      }

      it "raises a DownstreamInvariantError" do
        expect {
          mediator.send_to_live_content_store
        }.to raise_error(DownstreamInvariantError)
      end
    end
  end

  describe "#send_to_draft_content_store" do
    context "draft content item" do
      context "has base_path" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: draft_web_content_item,
            payload_version: payload_version,
          )
        }

        it "sends to draft content store" do
          expect(draft_content_store).to receive(:put_content_item)
          mediator.send_to_draft_content_store
        end

        it "doesn't send to live content store" do
          expect(live_content_store).to_not receive(:put_content_item)
          mediator.send_to_draft_content_store
        end
      end

      context "no base_path" do
        subject(:mediator) {
          DownstreamMediator.new(
            web_content_item: pathless_draft_web_content_item,
            payload_version: payload_version,
          )
        }

        it "raises DownstreamInvariantError" do
          expect {
            mediator.send_to_draft_content_store
          }.to raise_error(DownstreamInvariantError)
        end
      end
    end

    context "published content item" do
      subject(:mediator) {
        DownstreamMediator.new(
          web_content_item: live_web_content_item,
          payload_version: payload_version,
        )
      }

      it "sends to draft content store" do
        expect(draft_content_store).to receive(:put_content_item)
        mediator.send_to_draft_content_store
      end
    end

    context "unpublished content item" do
      subject(:mediator) {
        DownstreamMediator.new(
          web_content_item: withdrawn_unpublished_web_content_item,
          payload_version: payload_version,
        )
      }

      it "sends to draft content store" do
        expect(draft_content_store).to receive(:put_content_item)
        mediator.send_to_draft_content_store
      end
    end
  end

  describe "#delete_from_draft_content_store" do
    subject(:mediator) {
      DownstreamMediator.new(base_path: base_path, payload_version: payload_version)
    }
    it "delete item at base_path from draft content store" do
      expect(draft_content_store).to receive(:delete_content_item)
      mediator.delete_from_draft_content_store
    end
    it "doesn't delete at base_path for live content store" do
      expect(live_content_store).to_not receive(:delete_content_item)
      mediator.delete_from_draft_content_store
    end

    context "published item exists at base_path" do
      before do
        FactoryGirl.create(:live_content_item, base_path: base_path)
      end

      it "raises a DownstreamInvariantError" do
        expect {
          mediator.delete_from_draft_content_store
        }.to raise_error(DownstreamInvariantError)
      end
    end


    context "unpublished item exists at base_path" do
      before do
        FactoryGirl.create(:unpublished_content_item, base_path: base_path)
      end

      it "raises a DownstreamInvariantError" do
        expect {
          mediator.delete_from_draft_content_store
        }.to raise_error(DownstreamInvariantError)
      end
    end
  end

  describe "#broadcast_to_message_queue" do
    context "published content item" do
      subject(:mediator) {
        DownstreamMediator.new(
          web_content_item: live_web_content_item,
          payload_version: payload_version,
        )
      }

      it "broadcasts a message" do
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
          .with(a_hash_including(content_id: live_web_content_item.content_id))
        mediator.broadcast_to_message_queue("major")
      end

      it "uses update type provided" do
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
          .with(a_hash_including(update_type: "major"))
        mediator.broadcast_to_message_queue("major")
      end

      it "or content item update_type if none provided" do
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
          .with(a_hash_including(update_type: live_web_content_item.update_type))
        mediator.broadcast_to_message_queue(nil)
      end
    end

    context "unpublished content item" do
      subject(:mediator) {
        DownstreamMediator.new(
          web_content_item: draft_web_content_item,
          payload_version: payload_version,
        )
      }

      it "raises a DownstreamInvariantError" do
        expect {
          mediator.broadcast_to_message_queue("major")
        }.to raise_error(DownstreamInvariantError)
      end
    end
  end

  describe ".send_to_live_content_store" do
    it "can send an item to content store" do
      expect(live_content_store).to receive(:put_content_item)
      DownstreamMediator.send_to_live_content_store(live_web_content_item, payload_version)
    end
  end

  describe ".send_to_draft_content_store" do
    it "can send a content item to draft content store" do
      expect(draft_content_store).to receive(:put_content_item)
      DownstreamMediator.send_to_draft_content_store(draft_web_content_item, payload_version)
    end
  end

  describe ".delete_from_draft_content_store" do
    it "can delete an item from draft content store" do
      expect(draft_content_store).to receive(:delete_content_item)
      DownstreamMediator.delete_from_draft_content_store(base_path, payload_version)
    end
  end
end
