require "rails_helper"

RSpec.describe DownstreamDraftWorker do
  let(:content_item) { FactoryGirl.create(:draft_content_item, base_path: "/foo") }
  let(:base_arguments) {
    {
      "content_item_id" => content_item.id,
      "payload_version" => 1,
      "update_dependencies" => true,
      "alert_on_invalid_state_error" => true,
    }
  }
  let(:arguments) { base_arguments }

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

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end

    it "doesn't require alert_on_invalid_state_error" do
      expect {
        subject.perform(arguments.except("alert_on_invalid_state_error"))
      }.not_to raise_error
    end
  end

  describe "sends to draft content store" do
    context "content item has a base path" do
      it "sends put content to draft content store" do
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
        subject.perform(arguments)
      end

      it "receives the base path" do
        base_path = Location.where(content_item: content_item).pluck(:base_path).first
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
          .with(base_path, anything)
        subject.perform(arguments)
      end
    end

    context "content item has a nil base path" do
      it "doesn't send the item to the draft content store" do
        pathless = FactoryGirl.create(
          :draft_content_item,
          base_path: nil,
          document_type: "contact",
          schema_name: "contact",
        )

        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        subject.perform(arguments.merge("content_item_id" => pathless.id))
      end
    end
  end

  describe "update dependencies" do
    context "can update dependencies" do
      let(:arguments) { base_arguments.merge("update_dependencies" => true) }
      it "enqueues dependencies" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
        subject.perform(arguments)
      end
    end

    context "can not update dependencies" do
      let(:arguments) { base_arguments.merge("update_dependencies" => false) }
      it "doesn't enqueue dependencies" do
        expect(DependencyResolutionWorker).to_not receive(:perform_async)
        subject.perform(arguments)
      end
    end
  end

  describe "error alerting" do
    let(:message) { "Can only send draft, published and unpublished items to the draft content store" }
    let(:logger) { Sidekiq::Logging.logger }

    before do
      allow(DownstreamService).to receive(:update_draft_content_store)
        .and_raise(DownstreamInvalidStateError, message)
    end

    context "when alert_on_invalid_state_error is true" do
      let(:arguments) { base_arguments.merge("alert_on_invalid_state_error" => true) }
      it "notifies airbrake" do
        expect(Airbrake).to receive(:notify_or_ignore)
        subject.perform(arguments)
      end

      it "doesn't log the message" do
        expect(logger).to_not receive(:warn).with(message)
        subject.perform(arguments)
      end
    end

    context "when alert_on_invalid_state_error is false" do
      let(:arguments) { base_arguments.merge("alert_on_invalid_state_error" => false) }

      it "doesn't notify airbrake" do
        expect(Airbrake).to_not receive(:notify_or_ignore)
        subject.perform(arguments)
      end

      it "logs the message" do
        expect(logger).to receive(:warn).with(message)
        subject.perform(arguments)
      end
    end
  end
end
