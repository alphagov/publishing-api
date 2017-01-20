require "rails_helper"

RSpec.describe DownstreamDraftWorker do
  let(:edition) do
    FactoryGirl.create(:draft_edition, base_path: "/foo")
  end

  let(:base_arguments) do
    {
      "content_id" => edition.document.content_id,
      "locale" => "en",
      "payload_version" => 1,
      "update_dependencies" => true,
    }
  end

  let(:arguments) { base_arguments }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "arguments" do
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

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end
  end

  describe "sends to draft content store" do
    context "edition has a base path" do
      it "sends put content to draft content store" do
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
        subject.perform(arguments)
      end

      it "receives the base path" do
        base_path = Edition.where(id: edition.id).pluck(:base_path).first
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
          .with(base_path, anything)
        subject.perform(arguments)
      end
    end

    context "edition has a nil base path" do
      it "doesn't send the item to the draft content store" do
        pathless = FactoryGirl.create(:draft_edition,
          base_path: nil,
          document_type: "contact",
          schema_name: "contact",
        )

        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        subject.perform(arguments.merge("content_id" => pathless.document.content_id))
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
end
