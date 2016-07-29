require "rails_helper"

RSpec.describe DownstreamUnpublishWorker do
  let(:content_item) { FactoryGirl.create(:unpublished_content_item) }
  let(:payload_version) { 1 }
  let(:arguments) {
    {
      "content_item_id" => content_item.id,
      "payload_version" => payload_version,
      "update_dependencies" => true,
    }
  }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    stub_request(:delete, %r{.*content-store.*/content/.*})
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
  end

  describe "withdrawal unpublishing type" do
    let(:withdrawn_content_item) {
      FactoryGirl.create(:withdrawn_content_item, base_path: "/withdrawn")
    }

    it "sends to both content stores" do
      expect(Adapters::ContentStore).to receive(:put_content_item)
        .with("/withdrawn", a_hash_including(payload_version: payload_version))
      expect(Adapters::DraftContentStore).to receive(:put_content_item)
        .with("/withdrawn", a_hash_including(payload_version: payload_version))
      subject.perform(arguments.merge(content_item_id: withdrawn_content_item.id))
    end

    it "uses content store presenter" do
      expect(Presenters::ContentStorePresenter).to receive(:present)
      subject.perform(arguments.merge(content_item_id: withdrawn_content_item.id))
    end
  end

  describe "redirect unpublishing type" do
    let(:redirect_content_item) {
      FactoryGirl.create(
        :unpublished_content_item,
        base_path: "/redirect",
        unpublishing_type: "redirect",
        alternative_path: "/new-path",
      )
    }

    it "sends to both content stores" do
      expect(Adapters::ContentStore).to receive(:put_content_item)
        .with("/redirect", a_hash_including(payload_version: payload_version))
      expect(Adapters::DraftContentStore).to receive(:put_content_item)
        .with("/redirect", a_hash_including(payload_version: payload_version))
      subject.perform(arguments.merge(content_item_id: redirect_content_item.id))
    end

    it "uses redirect presenter" do
      expect(RedirectPresenter).to receive(:present)
        .with(a_hash_including(base_path: "/redirect", destination: "/new-path"))
        .and_return({})
      subject.perform(arguments.merge(content_item_id: redirect_content_item.id))
    end
  end

  describe "gone unpublishing type" do
    let(:gone_content_item) {
      FactoryGirl.create(
        :unpublished_content_item,
        base_path: "/gone",
        unpublishing_type: "gone",
        alternative_path: nil,
        explanation: "whoops",
      )
    }

    it "sends to both content stores" do
      expect(Adapters::ContentStore).to receive(:put_content_item)
        .with("/gone", a_hash_including(payload_version: payload_version))
      expect(Adapters::DraftContentStore).to receive(:put_content_item)
        .with("/gone", a_hash_including(payload_version: payload_version))
      subject.perform(arguments.merge(content_item_id: gone_content_item.id))
    end

    it "uses gone presenter" do
      expect(GonePresenter).to receive(:present)
        .with(a_hash_including(base_path: "/gone", alternative_path: nil, explanation: "whoops"))
        .and_return({})
      subject.perform(arguments.merge(content_item_id: gone_content_item.id))
    end
  end

  describe "vanish unpublishing type" do
    let(:vanish_content_item) {
      FactoryGirl.create(
        :unpublished_content_item,
        base_path: "/vanish",
        unpublishing_type: "vanish",
      )
    }

    it "deletes from the both content stores" do
      expect(Adapters::ContentStore).to receive(:delete_content_item).with("/vanish")
      expect(Adapters::DraftContentStore).to receive(:delete_content_item).with("/vanish")
      subject.perform(arguments.merge(content_item_id: vanish_content_item.id))
    end
  end

  describe "pathless content item" do
    let(:pathless) {
      FactoryGirl.create(
        :withdrawn_content_item,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact",
      )
    }

    it "doesn't update content store" do
      expect(Adapters::ContentStore).to_not receive(:put_content_item)
      subject.perform(arguments.merge("content_item_id" => pathless.id))
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

  describe "state protection" do
    it "accepts unpublished content items" do
      unpublished = FactoryGirl.create(:unpublished_content_item)

      expect {
        subject.perform(arguments.merge("content_item_id" => unpublished.id))
      }.not_to raise_error
    end

    it "rejects draft content items" do
      draft = FactoryGirl.create(:draft_content_item)

      expect {
        subject.perform(arguments.merge("content_item_id" => draft.id))
      }.to raise_error(CommandError)
    end

    it "rejects published content items" do
      live = FactoryGirl.create(:live_content_item)

      expect {
        subject.perform(arguments.merge("content_item_id" => live.id))
      }.to raise_error(CommandError)
    end

    it "rejects superseded content items" do
      superseded = FactoryGirl.create(:live_content_item, state: "superseded")

      expect {
        subject.perform(arguments.merge("content_item_id" => superseded.id))
      }.to raise_error(CommandError)
    end
  end
end
