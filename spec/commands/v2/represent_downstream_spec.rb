require "rails_helper"

RSpec.describe Commands::V2::RepresentDownstream do
  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "call" do
    before do
      2.times { FactoryGirl.create(:draft_edition) }
      FactoryGirl.create(:live_edition,
        document: FactoryGirl.create(:document, locale: "en"),
        document_type: "guidance",
      )
      FactoryGirl.create(:live_edition,
        document: FactoryGirl.create(:document, locale: "fr"),
        document_type: "guidance",
      )
      FactoryGirl.create(:live_edition, document_type: "press_release")
    end

    context "downstream live" do
      it "sends to downstream live worker" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .exactly(3).times
        subject.call(Document.pluck(:content_id), false)
      end

      it "uses 'downstream_low' queue" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with("downstream_low", anything)
          .at_least(1).times
        subject.call(Document.pluck(:content_id), false)
      end

      it "doesn't update dependencies" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(update_dependencies: false))
          .at_least(1).times
        subject.call(Document.pluck(:content_id), false)
      end

      it "has a message_queue_update_type of 'links'" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(message_queue_update_type: "links"))
          .at_least(1).times
        subject.call(Document.pluck(:content_id), false)
      end

      it "updates for each locale" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(locale: "en"))
          .exactly(2).times
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(locale: "fr"))
          .exactly(1).times
        subject.call(Document.pluck(:content_id), false)
      end
    end

    context "scope" do
      it "can specify a scope" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with("downstream_low", a_hash_including(:content_id, :locale, :payload_version))
          .exactly(2).times
        subject.call(Edition.joins(:document)
          .where(document_type: "guidance").pluck('documents.content_id'), false)
      end
    end

    context "drafts optional" do
      it "can send to downstream draft worker" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_low",
            a_hash_including(:content_id, :locale, :payload_version, update_dependencies: false)
          )
          .exactly(5).times
        subject.call(Document.pluck(:content_id), true)
      end

      it "can not send to downstream draft worker" do
        expect(DownstreamDraftWorker).to_not receive(:perform_async_in_queue)
        subject.call(Document.pluck(:content_id), false)
      end
    end
  end
end
