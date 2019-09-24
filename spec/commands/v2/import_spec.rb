require "rails_helper"

RSpec.describe Commands::V2::Import, type: :request do
  describe "#call" do
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/bar" }

    let(:content_item) do
      {
        document_type: "organisation",
        schema_name: "generic",
        publishing_app: "publisher",
        title: "foo",
        rendering_app: "government-frontend",
        base_path: base_path,
        routes: [{ "path": "/bar", "type": "exact" }],
        details: {},
        states: [{ name: "superseded" }],
      }
    end

    let(:payload) do
      {
        content_id: content_id,
        locale: "en",
        history: [
          content_item,
          content_item.merge(
            title: "bar",
          ),
          content_item.merge(
            states: [{ name: "published" }],
            update_type: "major",
          ),
        ],
      }
    end

    subject { described_class.call(payload) }

    it "creates the full content item history" do
      expect { subject }.to change { Edition.count }.by(3)
    end

    it "creates the state history" do
      subject
      expect(Edition.all.map(&:state)).to match_array(%w(superseded superseded published))
    end

    it "creates the full User facing version history" do
      subject
      expect(Edition.all.map(&:user_facing_version)).to match_array([1, 2, 3])
    end

    it "sets content_store correctly" do
      subject
      expect(
        Edition.all.pluck(:content_store),
      ).to match_array([nil, nil, "live"])
    end

    it "sends the last published item to the content_store" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
      subject
    end

    context "with a unpublished content item" do
      let!(:payload) do
        {
          content_id: content_id,
          locale: "en",
          history: [
            content_item.merge(
              states: [{
                name: "unpublished",
                type: "gone",
              }],
            ),
          ],
        }
      end

      it "correctly sets the unpublishing type" do
        subject

        document = Document.find_by(content_id: content_id, locale: "en")
        edition = Edition.find_by(document: document)
        unpublishing = Unpublishing.find_by(edition: edition)

        expect(unpublishing.type).to eq("gone")
      end

      context "when missing the type information" do
        let!(:payload) do
          {
            content_id: content_id,
            locale: "en",
            history: [
              content_item.merge(
                states: [{ name: "unpublished" }],
              ),
            ],
          }
        end

        it "raises a command error" do
          expect {
            subject.call
          }.to raise_error(
            CommandError,
            /For a state of unpublished, a type must be provided/,
          )
        end
      end
    end

    context "with history elements containing locale" do
      let!(:payload) do
        {
          content_id: content_id,
          locale: "en",
          history: [
            content_item.merge(
              locale: "cy",
            ),
          ],
        }
      end

      it "raises a command error" do
        expect {
          subject.call
        }.to raise_error(
          CommandError,
          /Unrecognised attributes in payload: \[:locale\]/,
        )
      end
    end

    context "with a invalid array of states" do
      def payload_for_states(states)
        history = states.map do |state|
          if state == "unpublished"
            state_hash = { name: state,
                           type: "withdrawal",
                           explanation: "placeholder" }
          else
            state_hash = { name: state }
          end

          content_item.merge(states: [state_hash])
        end

        {
          content_id: content_id,
          history: history,
        }
      end

      [%w(draft published),
       %w(draft draft),
       %w(published published),
       %w(superseded),
       %w(superseded superseded),
       %w(draft superseded),
       %w(published superseded),
       %w(unpublished superseded),
       %w(unpublished unpublished)].each do |states|
        let!(:payload) do
          payload_for_states(states)
        end

        it "rejects states: #{states}" do
          expect {
            subject.call
          }.to raise_error(CommandError)
        end
      end
    end

    context "with existing content" do
      let!(:first_payload) do
        payload.merge(
          history: [content_item.merge(states: [{ name: "published" }])],
        )
      end

      let(:second_base_path) { "/foo" }

      let!(:second_payload) do
        payload.merge(
          history: [
            content_item.merge(
              states: [{ name: "published" }],
              base_path: second_base_path,
              routes: [{ "path": second_base_path, "type": "exact" }],
            ),
          ],
        )
      end

      it "deletes removed content from the contet store" do
        def draft_path(base_path)
          Plek.new.find("draft-content-store") + "/content" + base_path
        end

        def live_path(base_path)
          Plek.new.find("content-store") + "/content" + base_path
        end

        described_class.call(first_payload)

        stubs = [
          stub_request(:put, live_path(second_base_path)),
          stub_request(:put, draft_path(second_base_path)),
          stub_request(:delete, live_path(base_path)),
          stub_request(:delete, draft_path(base_path)),
        ]

        described_class.call(second_payload)

        stubs.each do |stub|
          expect(stub).to have_been_requested.once
        end
      end
    end
  end
end
