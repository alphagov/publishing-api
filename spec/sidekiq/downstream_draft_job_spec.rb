RSpec.describe DownstreamDraftJob do
  let(:edition) do
    create(:draft_edition, base_path: "/foo")
  end
  let(:content_id) { edition.content_id }

  let(:base_arguments) do
    {
      "content_id" => content_id,
      "locale" => "en",
      "update_dependencies" => true,
    }
  end

  let(:arguments) { base_arguments }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  specify { expect(described_class).to have_valid_sidekiq_options }

  describe "arguments" do
    it "requires content_item_id or content_id" do
      expect {
        subject.perform(arguments.except("content_id"))
      }.to raise_error(KeyError)
      expect {
        subject.perform(arguments.merge("content_item_id" => edition.id))
      }.not_to raise_error
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
        base_path = Edition.where(id: edition.id).pick(:base_path)
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
          .with(base_path, anything)
        subject.perform(arguments)
      end
    end

    context "edition has a nil base path" do
      it "doesn't send the item to the draft content store" do
        pathless = create(
          :draft_edition,
          base_path: nil,
          document_type: "contact",
          schema_name: "contact",
        )

        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        subject.perform(arguments.merge("content_id" => pathless.document.content_id))
      end
    end
  end

  describe "updates expanded links" do
    it "creates a ExpandedLinks with_drafts: true entry" do
      expect { subject.perform(arguments) }
        .to(change { ExpandedLinks.exists?(content_id:, with_drafts: true) })
    end
    it "creates a ExpandedLinks with_drafts: false entry" do
      expect { subject.perform(arguments) }
        .to(change { ExpandedLinks.exists?(content_id:, with_drafts: false) })
    end

    context "when there aren't any links" do
      it "has only available_translations in the draft" do
        subject.perform(arguments)
        links = ExpandedLinks.find_by(content_id:, with_drafts: true)
          .expanded_links
        expect(links).to match a_hash_including("available_translations")
      end

      it "has no links without drafts" do
        subject.perform(arguments)
        links = ExpandedLinks.find_by(content_id:, with_drafts: false)
          .expanded_links
        expect(links).to match({})
      end
    end
  end

  describe "update dependencies" do
    context "can update dependencies" do
      let(:arguments) do
        base_arguments.merge("update_dependencies" => true, "source_command" => "command")
      end

      it "enqueues dependencies" do
        expect(DependencyResolutionJob).to receive(:perform_async)
        subject.perform(arguments)
      end

      it "sends the source command to the worker" do
        expect(DependencyResolutionJob).to receive(:perform_async)
          .with(a_hash_including("source_command" => "command"))
        subject.perform(arguments)
      end

      it "sends the document type to the worker" do
        expect(DependencyResolutionJob).to receive(:perform_async)
          .with(a_hash_including("source_document_type" => "services_and_information"))
        subject.perform(arguments)
      end

      it "sends the dependency resolution fields to the worker" do
        expect(DependencyResolutionJob).to receive(:perform_async)
          .with(a_hash_including("source_fields" => %w[field]))
        subject.perform(arguments.merge("source_fields" => %w[field]))
      end
    end

    context "can not update dependencies" do
      let(:arguments) { base_arguments.merge("update_dependencies" => false) }
      it "doesn't enqueue dependencies" do
        expect(DependencyResolutionJob).to_not receive(:perform_async)
        subject.perform(arguments)
      end
    end
  end
end
