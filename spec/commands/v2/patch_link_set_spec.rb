require "rails_helper"

RSpec.describe Commands::V2::PatchLinkSet do
  let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
  let(:content_id) { SecureRandom.uuid }
  let(:topics) { 3.times.map { SecureRandom.uuid } }
  let(:parent) { [SecureRandom.uuid] }

  let(:payload) do
    {
      content_id: content_id,
      links: {
        topics: topics,
        parent: parent,
      }
    }
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})

    allow(Presenters::ContentStorePresenter).to receive(:present)
      .and_return(expected_content_store_payload)
    allow(GdsApi::GovukHeaders).to receive(:headers)
      .and_return(govuk_request_id: "12345-67890")
  end

  context "when no link set exists" do
    it "creates the link set and associated links" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.content_id).to eq(content_id)

      links = link_set.links
      expect(links.map(&:link_type)).to eq(%w(topics topics topics parent))
      expect(links.map(&:target_content_id)).to eq(topics + parent)
    end

    it "doesn't reject an empty links hash, but doesn't delete links either" do
      link_set = FactoryGirl.create(
        :link_set,
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

      lock_version = LockVersion.find_by(target: link_set)
      expect(lock_version).to be_present
      expect(lock_version.number).to eq(1)
    end

    it "responds with a success object containing the newly created links" do
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
  end

  context "when a link set exists" do
    let(:related) { [SecureRandom.uuid] }

    before do
      link_set = FactoryGirl.create(
        :link_set,
        content_id: content_id,
        links: [
          FactoryGirl.create(
            :link,
            link_type: "topics",
            target_content_id: topics.first,
          ),
          FactoryGirl.create(
            :link,
            link_type: "topics",
            target_content_id: topics.second,
          ),
          FactoryGirl.create(
            :link,
            link_type: "related",
            target_content_id: related.first,
          ),
        ]
      )

      FactoryGirl.create(:lock_version, target: link_set, number: 1)
    end

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
      expect(topics_links.map(&:target_content_id)).to match_array(topics)
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

      lock_version = LockVersion.find_by(target: link_set)
      expect(lock_version).to be_present
      expect(lock_version.number).to eq(2)
    end

    it "responds with a success object containing the updated links" do
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
      create(
        :draft_content_item,
        content_id: content_id,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends a request to the draft content store" do
      expect(PresentedContentStoreWorker).to receive(:perform_async)
        .with(
          content_store: Adapters::DraftContentStore,
          payload: expected_content_store_payload,
          request_uuid: "12345-67890",
        )

      described_class.call(payload)
    end

    it "presents the draft content item for the downstream request" do
      expect(Presenters::ContentStorePresenter).to receive(:present)
        .with(draft_content_item, instance_of(Event))

      described_class.call(payload)
    end

    context "when a locale is specified" do
      before do
        payload[:locale] = "fr"
      end

      context "and a draft content item exists for that locale" do
        let!(:draft_content_item) do
          create(
            :draft_content_item,
            content_id: content_id,
            base_path: "/french-path",
            title: "French Title",
            locale: "fr",
          )
        end

        it "sends the draft content item for that locale downstream" do
          expect(Presenters::ContentStorePresenter).to receive(:present)
            .with(draft_content_item, instance_of(Event))

          expect(PresentedContentStoreWorker).to receive(:perform_async)
            .with(
              content_store: Adapters::DraftContentStore,
              payload: expected_content_store_payload,
              request_uuid: "12345-67890",
            )

          described_class.call(payload)
        end
      end

      context "and a draft content item does not exist for that locale" do
        it "does not send a downstream request" do
          expect(PresentedContentStoreWorker).not_to receive(:perform_async)
          expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

          described_class.call(payload)
        end
      end
    end

    context "when 'downstream' is false" do
      it "does not send a request to either content store" do
        expect(PresentedContentStoreWorker).not_to receive(:perform_async)
        described_class.call(payload, downstream: false)
      end

      it "does not send a message to the message queue" do
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
        described_class.call(payload, downstream: false)
      end
    end
  end

  context "when a live content item exists for the content_id" do
    let!(:live_content_item) do
      create(
        :live_content_item,
        content_id: content_id,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends a request to the live content store" do
      expect(PresentedContentStoreWorker).to receive(:perform_async)
        .with(
          content_store: Adapters::ContentStore,
          payload: expected_content_store_payload,
          request_uuid: "12345-67890",
        )

      described_class.call(payload)
    end

    it "presents the live content item for the downstream request" do
      expect(Presenters::ContentStorePresenter).to receive(:present)
        .with(live_content_item, instance_of(Event))

      described_class.call(payload)
    end

    it "sends a message to message queue" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(hash_including(
                content_id: content_id,
                title: "Some Title",
                links: {
                  topics: topics,
                  parent: parent,
                }))

      described_class.call(payload)
    end

    context "when a locale is specified" do
      before do
        payload[:locale] = "fr"
      end

      context "and a live content item exists for that locale" do
        let!(:live_content_item) do
          create(
            :live_content_item,
            content_id: content_id,
            base_path: "/french-path",
            title: "French Title",
            locale: "fr",
          )
        end

        it "sends the live content item for that locale downstream" do
          expect(PresentedContentStoreWorker).to receive(:perform_async)
            .with(
              content_store: Adapters::ContentStore,
              payload: expected_content_store_payload,
              request_uuid: "12345-67890",
            )

          expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
            .with(hash_including(title: "French Title"))

          described_class.call(payload)
        end
      end

      context "and a live content item does not exist for that locale" do
        it "does not send a downstream request" do
          expect(PresentedContentStoreWorker).not_to receive(:perform_async)
          expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

          described_class.call(payload)
        end
      end
    end


    context "when 'downstream' is false" do
      it "does not send a request to either content store" do
        expect(ContentStoreWorker).not_to receive(:perform_async)
        described_class.call(payload, downstream: false)
      end

      it "does not send a message to the message queue" do
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
        described_class.call(payload, downstream: false)
      end
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
