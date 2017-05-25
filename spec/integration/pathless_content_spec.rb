require "rails_helper"

RSpec.describe "pathless content" do
  describe Commands::V2::PutContent do
    describe "call" do
      let(:content_id) { FactoryGirl.build(:document).content_id }
      let(:payload) do
        {
          content_id: content_id,
          title: "Some Title",
          publishing_app: "publisher",
          rendering_app: "frontend",
          document_type: "contact",
          details: { title: "Contact Title" },
          schema_name: "contact",
          locale: "en",
          phase: "beta",
        }
      end

      context "schema validation" do
        context "when schema requires a base_path" do
          before { payload[:schema_name] = "nonexistent-schema" }

          it "raises an error" do
            expect {
              described_class.call(payload)
            }.to raise_error(CommandError, /Base path is not a valid absolute URL path/)
          end
        end

        context "when schema does not require a base_path" do
          it "does not raise an error" do
            expect {
              described_class.call(payload)
            }.not_to raise_error
          end

          it "does not try to reserve a path" do
            expect {
              described_class.call(payload)
            }.not_to change(PathReservation, :count)
          end
        end
      end

      context "with a pathless edition payload" do
        it "saves the content as draft" do
          expect {
            described_class.call(payload)
          }.to change(Edition, :count).by(1)
        end

        it "sends to the downstream draft worker" do
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          described_class.call(payload)
        end

        context "for an existing draft edition" do
          let!(:draft_edition) do
            FactoryGirl.create(:draft_edition,
              document: FactoryGirl.create(:document, content_id: content_id),
              title: "Old Title"
            )
          end

          it "updates the draft" do
            described_class.call(payload)
            expect(draft_edition.reload.title).to eq("Some Title")
          end
        end

        context "for an existing live edition" do
          let!(:live_edition) do
            FactoryGirl.create(:live_edition,
              document: FactoryGirl.create(:document, content_id: content_id),
              title: "Old Title"
            )
          end

          it "creates a new draft" do
            expect {
              described_class.call(payload)
            }.to change(Edition, :count).by(1)
          end
        end
      end

      context "where a base_path is optional and supplied" do
        before do
          payload.merge!(
            base_path: base_path,
            routes: [{ path: base_path, type: "exact" }],
          )
        end

        it "sends to the content-store" do
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          described_class.call(payload)
        end

        # This covers a specific edge case where the edition uniqueness validator
        # matched anything else with the same state, locale and version because it
        # was previously ignoring the base path, now it should return without
        # attempting to validate for pathless formats.
        context "with other similar pathless items" do
          before do
            FactoryGirl.create(:draft_edition,
              base_path: nil,
              schema_name: "contact",
              document_type: "contact",
              user_facing_version: 3,
            )
          end

          it "doesn't conflict" do
            expect {
              described_class.call(payload)
            }.not_to raise_error
          end
        end

        context "when there's a conflicting edition" do
          before do
            FactoryGirl.create(:draft_edition,
              base_path: base_path,
              schema_name: "contact",
              document_type: "contact",
              user_facing_version: 3,
            )
          end

          it "conflicts" do
            expect {
              described_class.call(payload)
            }.to raise_error(CommandError, /base path=\/vat-rates conflicts/)
          end
        end
      end
    end
  end

  describe Commands::V2::Publish do
    let(:pathless_edition) do
      FactoryGirl.create(:draft_edition,
        document_type: "contact",
        user_facing_version: 2,
        base_path: nil,
      )
    end

    let(:payload) do
      {
        content_id: pathless_edition.document.content_id,
        update_type: "major",
        previous_version: 1,
      }
    end

    context "with no Location" do
      it "publishes the item" do
        described_class.call(payload)

        updated_item = Edition.find(pathless_edition.id)
        expect(updated_item.state).to eq("published")
      end

      context "with a previously published item" do
        let!(:live_edition) do
          FactoryGirl.create(:live_edition,
            document: pathless_edition.document,
            document_type: "contact",
            user_facing_version: 1,
          )
        end

        it "publishes the draft" do
          described_class.call(payload)

          updated_item = Edition.find(pathless_edition.id)
          expect(updated_item.state).to eq("published")
        end
      end
    end
  end
end
