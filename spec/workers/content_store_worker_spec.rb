require "rails_helper"

RSpec.describe ContentStoreWorker do
  expectations = {
    200 => { raises_error: false, logs_to_airbrake: false },
    202 => { raises_error: false, logs_to_airbrake: false },
    400 => { raises_error: false, logs_to_airbrake: true },
    409 => { raises_error: false, logs_to_airbrake: true },
    500 => { raises_error: true, logs_to_airbrake: false },
  }

  def do_request
    subject.perform(
      content_store: "Adapters::ContentStore",
      content_item_id: ContentItem.last.id,
    )
  end

  expectations.each do |status, expectation|
    context "when the content store responds with a #{status}" do
      before do
        stub_request(:put, "http://content-store.dev.gov.uk/content/foo").
          to_return(status: status, body: {}.to_json)
      end

      let(:status) { status }
      let!(:content_item) { create(:live_content_item, base_path: '/foo') }

      if expectation.fetch(:raises_error)
        it "raises an error" do
          expect { do_request }.to raise_error(CommandError)
        end
      else
        it "does not raise an error" do
          expect { do_request }.to_not raise_error
        end
      end

      if expectation.fetch(:logs_to_airbrake)
        it "logs the response to airbrake" do
          expect(Airbrake).to receive(:notify_or_ignore)
          do_request rescue CommandError
        end
      else
        it "does not log the response to airbrake" do
          expect(Airbrake).to_not receive(:notify_or_ignore)
          do_request rescue CommandError
        end
      end
    end
  end

  context "when a draft item is enqueued" do
    let!(:draft_content_item) { create(:draft_content_item, base_path: '/foo') }

    it "publishes a presented draft content item to the draft Content Store" do
      api_call = stub_request(:put, "http://draft-content-store.dev.gov.uk/content/foo")

      subject.perform(
        content_store: 'Adapters::DraftContentStore',
        content_item_id: draft_content_item.id,
      )

      expect(api_call).to have_been_made
    end
  end

  context "when a live item is enqueued" do
    let!(:live_content_item)  { create(:live_content_item, base_path: '/foo') }

    it "publishes a presented live content item to the live Content Store" do
      api_call = stub_request(:put, "http://content-store.dev.gov.uk/content/foo")

      subject.perform(
        content_store: 'Adapters::ContentStore',
        content_item_id: live_content_item.id,
      )

      expect(api_call).to have_been_made
    end

    # TODO: investigate how this can happen
    context "when the live item has an access limit" do
      before do
        FactoryGirl.create(
          :access_limit,
          content_item: live_content_item,
          users: [SecureRandom.uuid],
        )
      end

      it "strips out access_limited from the downstream payload" do
        stub_request(:put, "http://content-store.dev.gov.uk/content/foo")

        do_request

        expect(
          a_request(:put, "http://content-store.dev.gov.uk/content/foo").with do |request|
            payload = JSON.parse(request.body)
            expect(payload.has_key?("access_limited")).to eq(false)
          end
        ).to have_been_made.once
      end

      it "notifies airbrake with some debugging information" do
        stub_request(:put, "http://content-store.dev.gov.uk/content/foo")

        expected_error = ConsistencyError.new(
          "Attempted to send access limited to the live content store for content id #{live_content_item.content_id}"
        )

        expect(Airbrake).to receive(:notify_or_ignore).with(expected_error)

        do_request
      end
    end
  end

  context "when a deletion is enqueued" do
    it "deletes the content item" do
      api_call = stub_request(:delete, "http://draft-content-store.dev.gov.uk/content/abc")

      subject.perform(
        content_store: 'Adapters::DraftContentStore',
        base_path: "/abc",
        delete: true,
      )

      expect(api_call).to have_been_made
    end
  end

  context "when a deletion is enqueued, but content-store doesn't have the item" do
    it "swallows the returned 404" do
      api_call = stub_request(:delete, "http://draft-content-store.dev.gov.uk/content/abc")
        .to_return(status: 404)

      expect(Airbrake).not_to receive(:notify_or_ignore)

      subject.perform(
        content_store: 'Adapters::DraftContentStore',
        base_path: "/abc",
        delete: true,
      )

      expect(api_call).to have_been_made
    end
  end

  context "when an enqueued item doesn't exist anymore" do
    let(:missing_content_item_id) { 123 }

    it "raises a more helpful error message" do
      expect {
        subject.perform(
          content_store: 'Adapters::ContentStore',
          content_item_id: missing_content_item_id,
        )
      }.to raise_error(
        ActiveRecord::RecordNotFound,
        /Tried to send ContentItem with id=123 to the Live Content Store/
      )
    end
  end
end
