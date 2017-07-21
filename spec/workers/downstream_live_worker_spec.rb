require "rails_helper"

RSpec.describe DownstreamLiveWorker do
  include GoogleAnalyticsTestHelper

  let(:edition) do
    FactoryGirl.create(:live_edition, base_path: "/foo")
  end

  let(:base_arguments) do
    {
      "content_id" => edition.document.content_id,
      "locale" => "en",
      "payload_version" => 1,
      "message_queue_update_type" => "major",
      "update_dependencies" => true,
    }
  end

  let(:arguments) { base_arguments }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "arguments" do
    before do
      stub_generic_ga_request
    end

    it "requires content_item_id or content_id" do
      expect {
        subject.perform(arguments.except("content_id"))
      }.to raise_error(KeyError)
      expect {
        subject.perform(arguments.merge("content_item_id" => edition.id))
      }.not_to raise_error
    end

    it "requires payload_version" do
      expect {
        subject.perform(arguments.except("payload_version"))
      }.to raise_error(KeyError)
    end

    it "doesn't require message_queue_update_type" do
      expect {
        subject.perform(arguments.except("message_queue_update_type"))
      }.not_to raise_error
    end

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end
  end

  describe "send to live content store" do
    context "published edition" do
      it "sends content to live content store" do
        stub_generic_ga_request
        expect(Adapters::ContentStore).to receive(:put_content_item)
        subject.perform(arguments)
      end

      it "sends GA event with first_published_at" do
        stub_first_published_at_ga_request(edition)

        subject.perform(arguments)

        expect(a_request(:post, /google-analytics.com\/collect/).
            with(body: { 'v': '1', 'tid': 'UA-26179049-1', 'cid': '660ad712-9753-4cb9-97a7-c9e9f13c318e', 't': 'event', 'cd90': edition.first_published_at },
                 headers: { 'Accept': '*/*', 'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type': 'application/x-www-form-urlencoded', 'Host': 'www.google-analytics.com', 'User-Agent': 'Ruby' })).
            to have_been_made
      end
    end

    context "unpublished edition" do
      let(:unpublished_edition) { FactoryGirl.create(:unpublished_edition) }
      let(:unpublished_arguments) { arguments.merge(content_id: unpublished_edition.document.content_id) }

      it "sends content to live content store" do
        stub_generic_ga_request
        expect(Adapters::ContentStore).to receive(:put_content_item)
        subject.perform(unpublished_arguments)
      end

      it "does not send a GA event with the first_published_at date" do
        stub_first_published_at_ga_request(edition)

        expect(a_request(:post, /google-analytics.com\/collect/)).to_not have_been_made

        subject.perform(unpublished_arguments)
      end
    end

    context "superseded edition" do
      let(:superseded_edition) { FactoryGirl.create(:superseded_edition) }
      let(:superseded_arguments) { arguments.merge(content_id: superseded_edition.document.content_id) }

      it "doesn't send to live content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        subject.perform(superseded_arguments)
      end

      it "does not send a GA event with the first_published_at date" do
        stub_first_published_at_ga_request(edition)

        expect(a_request(:post, /google-analytics.com\/collect/)).to_not have_been_made

        subject.perform(superseded_arguments)
      end

      it "absorbs an error" do
        expect(Airbrake).to receive(:notify)
          .with(an_instance_of(AbortWorkerError), a_hash_including(:parameters))
        subject.perform(superseded_arguments)
      end
    end

    it "wont send to content store without a base_path" do
      stub_generic_ga_request
      pathless = FactoryGirl.create(:live_edition,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact"
      )
      expect(Adapters::ContentStore).to_not receive(:put_content_item)
      subject.perform(arguments.merge("content_id" => pathless.document.content_id))
    end
  end

  describe "broadcast to message queue" do
    before do
      stub_generic_ga_request
    end

    it "sends a message" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)

      subject.perform(arguments)
    end

    it "uses the `message_queue_update_type`" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(hash_including(update_type: "minor"))

      subject.perform(arguments.merge("message_queue_update_type" => "minor"))
    end
  end

  describe "update dependencies" do
    before do
      stub_generic_ga_request
    end
    context "can update dependencies" do
      it "enqueues dependencies" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
        subject.perform(arguments.merge("update_dependencies" => true))
      end
    end

    context "can not update dependencies" do
      it "doesn't enqueue dependencies" do
        expect(DependencyResolutionWorker).to_not receive(:perform_async)
        subject.perform(arguments.merge("update_dependencies" => false))
      end
    end
  end

  describe "draft-to-live protection" do
    before do
      stub_generic_ga_request
    end

    it "rejects draft editions" do
      draft = FactoryGirl.create(:draft_edition)

      expect(Airbrake).to receive(:notify)
        .with(an_instance_of(AbortWorkerError), a_hash_including(:parameters))
      subject.perform(arguments.merge("content_id" => draft.document.content_id))
    end

    it "allows live editions" do
      live = FactoryGirl.create(:live_edition)

      expect(Airbrake).to_not receive(:notify)
      subject.perform(arguments.merge("content_id" => live.document.content_id))
    end
  end

  describe "no edition" do
    it "swallows the error" do
      expect(Airbrake).to receive(:notify)
        .with(an_instance_of(AbortWorkerError), a_hash_including(:parameters))
      subject.perform(arguments.merge("content_id" => SecureRandom.uuid))
    end
  end
end
