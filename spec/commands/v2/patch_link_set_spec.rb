require "rails_helper"

RSpec.describe Commands::V2::PatchLinkSet do
  let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
  let(:content_id) { SecureRandom.uuid }
  let(:topics) { 3.times.map { SecureRandom.uuid } }
  let(:topics_shuffled) { topics.shuffle }
  let(:parent) { [SecureRandom.uuid] }

  let(:payload) do
    {
      content_id: content_id,
      links: {
        topics: topics * 2, # test deduplication
        parent: parent,
      }
    }
  end

  # Shuffle the order of the links to test preservation of ordering
  let(:payload_shuffled) do
    {
      content_id: content_id,
      links: {
        topics: topics_shuffled * 2, # test deduplication
        parent: parent,
      }
    }
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})

    allow(Presenters::ContentStorePresenter).to receive(:present)
      .and_return(expected_content_store_payload)
  end

  shared_examples "creates an action" do
    it "creates an action" do
      expect(Action.count).to be 0
      described_class.call(payload)
      expect(Action.count).to be 1
      expect(Action.first.attributes).to match a_hash_including(
        "content_id" => content_id,
        "action" => "PatchLinkSet",
      )
    end
  end

  context "when no link set exists" do
    include_examples "creates an action"

    it "creates the link set and associated links" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.content_id).to eq(content_id)

      links = link_set.links
      expect(links.map(&:link_type)).to eq(%w(parent topics topics topics))
      expect(links.map(&:target_content_id)).to eq(parent + topics)
    end

    it "doesn't reject an empty links hash, but doesn't delete links either" do
      link_set = FactoryGirl.create(:link_set,
        links: [
          FactoryGirl.create(:link)
        ]
      )

      FactoryGirl.create(:lock_version, target: link_set)

      described_class.call(
        content_id: link_set.content_id,
        links: {}
      )

      expect(link_set.links.count).to eql(1)
    end

    it "creates a lock version for the link set" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.stale_lock_version).to eq(1)
    end

    it "responds with a success object containing the newly created links in the same order as in the request" do
      result = described_class.call(payload)

      expect(result).to be_a(Commands::Success)
      expect(result.data).to eq(
        content_id: content_id,
        version: 1,
        links: {
          topics: topics,
          parent: parent,
        },
      )
    end

    it "re-orders the links when the ordering is changed in the request" do
      described_class.call(payload_shuffled)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.content_id).to eq(content_id)

      links = link_set.links
      expect(links.map(&:link_type)).to eq(%w(parent topics topics topics))
      expect(links.map(&:target_content_id)).to eq(parent + topics_shuffled)
    end
  end

  context "when a link set exists" do
    let(:related) { [SecureRandom.uuid] }

    before do
      link_set = FactoryGirl.create(:link_set,
        content_id: content_id,
        links: [
          FactoryGirl.create(:link,
            link_type: "topics",
            target_content_id: topics.first,
          ),
          FactoryGirl.create(:link,
            link_type: "topics",
            target_content_id: topics.second,
          ),
          FactoryGirl.create(:link,
            link_type: "related",
            target_content_id: related.first,
          ),
        ]
      )

      FactoryGirl.create(:lock_version, target: link_set, number: 1)
    end

    include_examples "creates an action"

    it "creates links for groups that appear in the payload and not in the database" do
      described_class.call(payload)

      link_set = LinkSet.last
      links = link_set.links

      parent_links = links.where(link_type: "parent")
      expect(parent_links.map(&:target_content_id)).to eq(parent)
    end

    it "updates links for groups that appear in the payload and in the database" do
      described_class.call(payload)

      link_set = LinkSet.last
      links = link_set.links

      topics_links = links.where(link_type: "topics")
      expect(topics_links.map(&:target_content_id)).to eq(topics)
    end

    it "does not affect links for groups that do not appear in the payload" do
      described_class.call(payload)

      link_set = LinkSet.last
      links = link_set.links

      related_links = links.where(link_type: "related")
      expect(related_links.map(&:target_content_id)).to eq(related)
    end

    it "increments the lock version for the link set" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.stale_lock_version).to eq(2)
    end

    it "responds with a success object containing the updated links in the same order as in the request" do
      result = described_class.call(payload)

      expect(result).to be_a(Commands::Success)
      expect(result.data).to eq(
        content_id: content_id,
        version: 2,
        links: {
          topics: topics,
          parent: parent,
          related: related,
        }
      )
    end

    context "with a 'previous_version' that matches the lock version" do
      before do
        payload[:previous_version] = 1
      end

      it "does not raise an error" do
        expect {
          described_class.call(payload)
        }.not_to raise_error
      end
    end

    context "with a 'previous_version' that does not match the lock version" do
      before do
        payload[:previous_version] = 2
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /Conflict/)
      end
    end
  end

  context "when a draft content item exists for the content_id" do
    let!(:draft_content_item) do
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends to the downstream draft worker" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(:content_id, :locale, :payload_version),
        )

      described_class.call(payload)
    end

    it "sends a low priority request to the downstream draft worker for bulk publishing" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        .with("downstream_low", anything)

      described_class.call(payload.merge(bulk_publishing: true))
    end

    context "when a draft content item has multiple translations" do
      let!(:french_draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: "/french-path",
          title: "French Title",
          locale: "fr",
        )
      end

      it "sends the draft content items for all locales downstream" do
        %w(en fr).each do |locale|
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
            .with(
              "downstream_high",
              a_hash_including(
                content_id: content_id,
                locale: locale,
                payload_version: an_instance_of(Fixnum),
              ),
            )
        end

        described_class.call(payload)
      end
    end

    context "when 'downstream' is false" do
      it "does not send a request to either content store" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        described_class.call(payload, downstream: false)
      end
    end
  end

  context "when a live content item exists for the content_id" do
    let!(:live_content_item) do
      FactoryGirl.create(:live_content_item,
        content_id: content_id,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends to downstream live worker" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(
            :content_id,
            :locale,
            :payload_version,
            message_queue_update_type: "links",
          ),
        )

      described_class.call(payload)
    end

    it "sends a low priority request to the downstream live worker for bulk publishing" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_low",
          a_hash_including(
            :content_id,
            :locale,
            :payload_version,
            message_queue_update_type: "links",
          ),
        )

      described_class.call(payload.merge(bulk_publishing: true))
    end

    context "when a live content item has multiple translations" do
      let!(:french_live_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: "/french-path",
          title: "French Title",
          locale: "fr",
        )
      end

      it "sends the live content item for all locales downstream" do
        %w(en fr).each do |locale|
          expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
            .with(
              "downstream_high",
              content_id: content_id,
              locale: locale,
              payload_version: an_instance_of(Fixnum),
              message_queue_update_type: "links",
            )
        end

        described_class.call(payload)
      end
    end

    context "when 'downstream' is false" do
      it "does not send a request to presented content store worker" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        described_class.call(payload, downstream: false)
      end

      it "does not send a request to downstream live worker" do
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)
        described_class.call(payload, downstream: false)
      end
    end
  end

  context "when an unpublished content item exists for the content_id" do
    let!(:unpublished_content_item) do
      FactoryGirl.create(:unpublished_content_item,
        content_id: content_id,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends to downstream draft worker" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(
            :content_id,
            :locale,
            :payload_version
          ),
        )

      described_class.call(payload)
    end

    it "sends to downstream live worker" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(
            :content_id,
            :locale,
            :payload_version,
            message_queue_update_type: "links",
          ),
        )

      described_class.call(payload)
    end
  end

  context "when 'links' is missing from the payload" do
    before do
      payload.delete(:links)
    end

    it "raises a command error" do
      expect {
        described_class.call(payload)
      }.to raise_error(CommandError, "Links are required")
    end
  end

  context "when 'links' is nil in the payload" do
    before do
      payload[:links] = nil
    end

    it "raises a command error" do
      expect {
        described_class.call(payload)
      }.to raise_error(CommandError, "Links are required")
    end
  end

  it_behaves_like TransactionalCommand
end
