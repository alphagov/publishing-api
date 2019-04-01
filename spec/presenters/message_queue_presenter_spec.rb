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
    let(:workflow_message) { "Something changed" }
    let(:edition) {
      create(:draft_edition,
        update_type: update_type,
        schema_name: "calendar",
        document_type: "calendar")
    }

    subject(:result) do
      described_class.new(
        edition, draft: false, workflow_message: workflow_message,
      ).for_message_queue(payload_version)
    end

    it "calls the underlying #for_message_queue method on EditionPresenter" do
      result
      expect(edition_presenter).to have_received(:for_message_queue).with(payload_version)
    end

    context "with a workflow message" do
      it "presents the workflow message" do
        expect(result).to eq(foo: "foo", workflow_message: "Something changed")
      end
    end

    context "without a workflow message" do
      let(:workflow_message) { nil }

      it "omits the workflow message key" do
        expect(result).to eq(foo: "foo")
      end
    end
  end
end
