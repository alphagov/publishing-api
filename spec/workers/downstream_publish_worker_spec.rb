require "rails_helper"

RSpec.describe DownstreamPublishWorker do
  let(:content_item) { FactoryGirl.create(:live_content_item, base_path: "/foo") }
  let(:arguments) {
    {
      "content_item_id" => content_item.id,
      "payload_version" => 1,
      "message_queue_update_type" => "major",
      "update_dependencies" => true,
    }
  }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "arguments" do
    it "requires content_item_id" do
      expect {
        subject.perform(arguments.except("content_item_id"))
      }.to raise_error(KeyError)
    end

    it "requires payload_version" do
      expect {
        subject.perform(arguments.except("payload_version"))
      }.to raise_error(KeyError)
    end

    it "requires message_queue_update_type" do
      expect {
        subject.perform(arguments.except("message_queue_update_type"))
      }.to raise_error(KeyError)
    end

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end
  end

  describe "send to live content store" do
    context "can send to content store" do
      it "sends put content to live content store" do
        expect(Adapters::ContentStore).to receive(:put_content_item)
        subject.perform(arguments)
      end

      it "receives the base path" do
        base_path = Location.where(content_item: content_item).pluck(:base_path).first
        expect(Adapters::ContentStore).to receive(:put_content_item)
          .with(base_path, anything)
        subject.perform(arguments)
      end
    end

    it "wont send to content store without a base_path" do
      pathless = FactoryGirl.create(
        :live_content_item,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact"
      )
      expect(Adapters::ContentStore).to_not receive(:put_content_item)
      subject.perform(arguments.merge("content_item_id" => pathless.id))
    end
  end

  describe "broadcast to message queue" do
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
    it "rejects draft content items" do
      draft = FactoryGirl.create(:draft_content_item)

      expect {
        subject.perform(arguments.merge("content_item_id" => draft.id))
      }.to raise_error(CommandError)
    end

    it "allows live content items" do
      live = FactoryGirl.create(:live_content_item)

      expect {
        subject.perform(arguments.merge("content_item_id" => live.id))
      }.not_to raise_error
    end
  end
end
