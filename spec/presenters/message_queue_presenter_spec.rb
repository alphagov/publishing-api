require 'rails_helper'

RSpec.describe Presenters::MessageQueuePresenter do
  let(:payload_version) { 1 }
  let(:edition_presenter) { double(:edition_presenter) }

  before do
    allow(Presenters::EditionPresenter).to receive(:new)
      .with(edition, draft: false)
      .and_return(edition_presenter)
    allow(edition_presenter).to receive(:for_message_queue)
      .and_return(foo: "foo")
  end

  describe "#for_message_queue" do
    let(:update_type) { "minor" }
    let(:publishing_app) { "super-publisher" }
    let(:workflow_message) { "Something changed" }
    let(:edition) {
      create(:draft_edition,
        update_type: update_type,
        schema_name: "calendar",
        document_type: "calendar")
    }

    subject(:result) do
      described_class.new(
        edition,
        draft: false,
        notification_attributes: {
          publishing_app: publishing_app,
          workflow_message: workflow_message,
        }
      ).for_message_queue(payload_version)
    end

    it "calls the underlying #for_message_queue method on EditionPresenter" do
      result
      expect(edition_presenter).to have_received(:for_message_queue).with(payload_version)
    end

    context "with notification attributes" do
      it "presents the publishing app" do
        expect(result[:publishing_app]).to eq("super-publisher")
      end

      it "presents the workflow message" do
        expect(result[:workflow_message]).to eq("Something changed")
      end
    end

    context "without a workflow message" do
      let(:workflow_message) { nil }

      it "omits the workflow message entirely" do
        expect(result).to eq(foo: "foo", publishing_app: "super-publisher")
      end
    end

    context "without a publishing app" do
      let(:publishing_app) { nil }

      it "omits the publishing app entirely" do
        expect(result).to eq(foo: "foo", workflow_message: "Something changed")
      end
    end
  end
end
