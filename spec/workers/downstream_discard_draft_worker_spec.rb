require "rails_helper"

RSpec.describe DownstreamDiscardDraftWorker do
  let(:content_item) { FactoryGirl.create(:draft_content_item, base_path: "/foo") }
  let(:arguments) {
    {
      "base_path" => "/foo",
      "content_id" => content_item.content_id,
      "payload_version" => 1,
      "update_dependencies" => true,
    }
  }

  before do
    content_item.destroy
    stub_request(:delete, %r{.*content-store.*/content/.*})
  end

  describe "arguments" do
    it "requires base_path" do
      expect {
        subject.perform(arguments.except("base_path"))
      }.to raise_error(KeyError)
    end

    it "requires content_id" do
      expect {
        subject.perform(arguments.except("content_id"))
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
  end

  describe "deletes from draft content store" do
    context "can send to content store" do
      it "sends delete content to draft content store" do
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        subject.perform(arguments)
      end

      it "receives the base path" do
        base_path = Location.where(content_item: content_item).pluck(:base_path).first
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
          .with(base_path)
        subject.perform(arguments)
      end
    end

    it "wont send to content store without a base_path" do
      pathless = FactoryGirl.create(
        :draft_content_item,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact"
      )
      expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
      subject.perform(
        arguments.merge("content_id" => pathless.content_id, "base_path" => nil)
      )
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

  describe "conflict protection" do
    let(:content_id) { content_item.content_id }

    it "rejects if a draft item has the base path" do
      FactoryGirl.create(:draft_content_item, base_path: "/foo")

      expect {
        subject.perform(arguments.merge("base_path" => "/foo"))
      }.to raise_error(CommandError, /Cannot delete/)
    end

    it "rejects if a live item has the base path" do
      FactoryGirl.create(:live_content_item, base_path: "/bar")

      expect {
        subject.perform(arguments.merge("base_path" => "/bar"))
      }.to raise_error(CommandError, /Cannot delete/)
    end
  end
end
