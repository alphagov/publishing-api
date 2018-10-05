require "rails_helper"

RSpec.describe DownstreamDiscardDraftWorker do
  let(:base_path) { "/foo" }

  let(:edition) do
    create(:draft_edition,
      base_path: base_path,
      title: "Draft")
  end

  let(:content_id) { edition.content_id }

  let(:arguments) do
    {
      "base_path" => base_path,
      "content_id" => content_id,
      "locale" => "en",
      "update_dependencies" => true,
      "alert_on_base_path_conflict" => false
    }
  end

  before do
    edition.destroy
    stub_request(:put, %r{.*content-store.*/content/.*})
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

    it "requires locale" do
      expect {
        subject.perform(arguments.except("locale"))
      }.to raise_error(KeyError)
    end

    it "doesn't require live_content_item_id" do
      expect {
        subject.perform(arguments.except("live_content_item_id"))
      }.not_to raise_error
    end

    it "doesn't require alert_on_base_path_conflict" do
      expect {
        subject.perform(arguments.except("alert_on_base_path_conflict"))
      }.not_to raise_error
    end

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end
  end

  context "has a live edition with same base_path" do
    let!(:live_edition) do
      create(:live_edition,
        base_path: base_path,
        document: edition.document,
        title: "live")
    end
    let(:live_content_item_arguments) do
      arguments.merge("live_content_item_id" => live_edition.id)
    end

    it "adds the live edition to the draft content store" do
      expect(Adapters::DraftContentStore).to receive(:put_content_item)
        .with(base_path, a_hash_including(title: live_edition.title))
      subject.perform(live_content_item_arguments)
    end

    it "doesn't delete from the draft content store" do
      expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
      subject.perform(live_content_item_arguments)
    end
  end

  context "has a live edition with a different base_path" do
    let(:live_edition) do
      create(:live_edition,
        base_path: "/bar",
        document: edition.document,
        title: "Live")
    end
    let(:live_content_item_arguments) do
      arguments.merge("live_content_item_id" => live_edition.id)
    end

    it "adds the live edition to the draft content store" do
      expect(Adapters::DraftContentStore).to receive(:put_content_item)
        .with("/bar", a_hash_including(title: live_edition.title))
      subject.perform(live_content_item_arguments)
    end

    it "deletes from the draft content store" do
      expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        .with(base_path)
      subject.perform(live_content_item_arguments)
    end
  end

  context "doesn't have a live edition" do
    it "doesn't add to live draft content store" do
      expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
      subject.perform(arguments)
    end

    it "deletes from the draft content store" do
      expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        .with(base_path)
      subject.perform(arguments)
    end
  end

  describe "deletes from draft content store" do
    context "can send to content store" do
      it "sends delete content to draft content store" do
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        subject.perform(arguments)
      end

      it "receives the base path" do
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
          .with(base_path)
        subject.perform(arguments)
      end
    end

    it "wont send to content store without a base_path" do
      pathless = create(:draft_edition,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact")
      expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
      subject.perform(
        arguments.merge("content_id" => pathless.document.content_id, "base_path" => nil)
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

  describe "update expanded links" do
    context "when there is not an edition" do
      before do
        create(:expanded_links, content_id: content_id, with_drafts: true)
        create(:event, content_id: content_id)
      end

      it "deletes the expanded links" do
        expect { subject.perform(arguments) }
          .to change { ExpandedLinks.exists?(content_id: content_id, with_drafts: true) }
          .from(true).to(false)
      end
    end

    context "when there is an edition" do
      let!(:live_edition) do
        create(:live_edition, document: edition.document)
      end
      it "updates expanded links" do
        expect { subject.perform(arguments) }
          .to change { ExpandedLinks.exists?(content_id: content_id, with_drafts: true) }
          .from(false).to(true)
      end
    end
  end

  describe "conflict protection" do
    let(:content_id) { edition.content_id }
    let(:logger) { Sidekiq::Logging.logger }

    before do
      create(:live_edition, base_path: "/foo")
    end

    it "doesn't delete edition from content store" do
      expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
      subject.perform(arguments)
    end

    it "logs the conflict" do
      expect(Sidekiq::Logging.logger).to receive(:warn)
        .with(%r{Cannot discard '/foo'})
      subject.perform(arguments)
    end
  end
end
