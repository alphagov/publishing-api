require "rails_helper"

RSpec.describe Commands::V2::Publish do
  describe "call" do
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }
    let(:user_facing_version) { 5 }

    let!(:document) do
      FactoryGirl.create(:document,
        locale: locale,
        stale_lock_version: 2)
    end

    let!(:draft_item) do
      FactoryGirl.create(:draft_content_item,
        document: document,
        base_path: base_path,
        user_facing_version: user_facing_version,
      )
    end

    let(:expected_content_store_payload) { { base_path: base_path } }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})

      allow(DependencyResolutionWorker).to receive(:perform_async)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    let(:payload) do
      {
        content_id: document.content_id,
        update_type: "major",
        previous_version: 2,
      }
    end

    context "with no update_type" do
      before do
        payload.delete(:update_type)
      end

      context "with an update_type stored on the draft content item" do
        before do
          draft_item.update_attributes!(update_type: "major")
        end

        it "uses the update_type from the draft content item" do
          expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
            .with("downstream_high", hash_including(message_queue_update_type: "major"))

          described_class.call(payload)
        end
      end

      context "without an update_type stored on the draft content item" do
        before do
          draft_item.update_attributes!(update_type: nil)
        end

        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /update_type is required/)
        end
      end
    end

    context "when the content item was previously published" do
      let(:existing_base_path) { base_path }

      let!(:live_item) do
        FactoryGirl.create(:live_content_item,
          document: draft_item.document,
          base_path: existing_base_path,
          user_facing_version: user_facing_version - 1,
        )
      end

      it "marks the previously published item as 'superseded'" do
        described_class.call(payload)

        new_item = Edition.find(live_item.id)
        expect(new_item.state).to eq("superseded")
      end
    end

    context "when the content item was previously unpublished" do
      let!(:live_item) do
        FactoryGirl.create(:unpublished_content_item,
          document: draft_item.document,
          base_path: base_path,
          user_facing_version: user_facing_version - 1,
        )
      end

      it "marks the previously unpublished item as 'superseded'" do
        described_class.call(payload)

        new_item = Edition.find(live_item.id)
        expect(new_item.state).to eq("superseded")
      end
    end

    context "with another content item blocking the publish action" do
      let(:draft_locale) { draft_item.locale }

      let!(:other_content_item) do
        FactoryGirl.create(:redirect_live_content_item,
          locale: draft_locale,
          base_path: base_path,
        )
      end

      it "unpublishes the content item which is in the way" do
        described_class.call(payload)

        updated_other_content_item = Edition.find(other_content_item.id)

        expect(updated_other_content_item.state).to eq("unpublished")
        expect(updated_other_content_item.locale).to eq(draft_locale)
        expect(updated_other_content_item.base_path).to eq(base_path)
      end
    end

    context "with a 'previous_version' which does not match the current lock version of the draft item" do
      before do
        payload.merge!(previous_version: 1)
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /Conflict/)
      end
    end

    context "with a valid payload" do
      it "changes the state of the draft item to 'published'" do
        described_class.call(payload)

        updated_draft_item = Edition.find(draft_item.id)
        expect(updated_draft_item.state).to eq("published")
      end

      it "sends downstream asynchronously" do
        expect(DownstreamLiveWorker)
          .to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(:content_id, :locale, :payload_version),
          )

        described_class.call(payload)
      end

      it "creates an action" do
        expect(Action.count).to be 0
        described_class.call(payload)
        expect(Action.count).to be 1
        expect(Action.first.attributes).to match a_hash_including(
          "content_id" => document.content_id,
          "locale" => locale,
          "action" => "Publish",
        )
      end

      context "when the 'downstream' parameter is false" do
        it "does not send downstream" do
          expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)
          described_class.call(payload, downstream: false)
        end
      end

      context "with a public_updated_at set on the draft content item" do
        let(:public_updated_at) { Time.zone.now - 1.year }

        before do
          draft_item.update_attributes!(public_updated_at: public_updated_at)
        end

        it "uses the stored timestamp for major or minor" do
          described_class.call(payload)

          expect(draft_item.reload.public_updated_at).to be_within(1.second).of(public_updated_at)
        end
      end

      context "with no public_updated_at set on the draft content item" do
        before do
          draft_item.update_attributes!(public_updated_at: nil)
        end

        context "for a major update" do
          it "updates the public_updated_at time to now" do
            described_class.call(payload)

            expect(draft_item.reload.public_updated_at).to be_within(1.second).of(Time.zone.now)
          end
        end

        context "for a minor update" do
          before do
            payload.merge!(update_type: "minor")
          end

          it "preserves the public_updated_at value from the last published item" do
            public_updated_at = Time.zone.now - 2.years

            FactoryGirl.create(:live_content_item,
              document: draft_item.document,
              public_updated_at: public_updated_at,
              base_path: base_path,
            )

            described_class.call(payload)

            expect(Edition.last.public_updated_at.iso8601).to eq(public_updated_at.iso8601)
          end

          it "preserves the public_updated_at value from the last unpublished item" do
            public_updated_at = Time.zone.now - 2.years

            FactoryGirl.create(:unpublished_content_item,
              document: draft_item.document,
              public_updated_at: public_updated_at,
              base_path: base_path,
            )

            described_class.call(payload)

            expect(Edition.last.public_updated_at.iso8601).to eq(public_updated_at.iso8601)
          end
        end

        context "for a republish" do
          let(:public_updated_at) { Time.zone.now - 1.year }

          before do
            draft_item.update_attributes!(public_updated_at: public_updated_at)
            payload.merge!(update_type: "republish")
          end

          it "uses the stored timestamp for major or minor" do
            expect(DownstreamLiveWorker)
              .to receive(:perform_async_in_queue)
              .with(
                "downstream_low",
                a_hash_including(:content_id, :locale, :payload_version, message_queue_update_type: "republish"),
              )

            described_class.call(payload)
          end
        end
      end

      context "update_type changes from major to minor" do
        before do
          draft_item.update(update_type: "major")
          payload[:update_type] = "minor"
          ChangeNote.create(content_item: draft_item)
        end
        it "deletes associated ChangeNote records" do
          expect { described_class.call(payload) }
            .to change { ChangeNote.count }.by(-1)
        end
      end
    end

    context "with a first_published_at set on the draft content item" do
      let(:first_published_at) { Time.zone.now - 1.year }

      before do
        draft_item.update_attributes!(first_published_at: first_published_at)
      end

      it "uses the stored timestamp" do
        described_class.call(payload)

        expect(draft_item.reload.first_published_at).to be_within(1.second).of(first_published_at)
      end
    end

    context "with no first_published_at set on the draft content item" do
      before do
        draft_item.update_attributes!(first_published_at: nil)
      end

      it "updates the first_published_at time to now" do
        described_class.call(payload)

        expect(draft_item.reload.first_published_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context "when the base_path differs from the previously published item" do
      let!(:live_item) do
        FactoryGirl.create(:live_content_item,
          document: draft_item.document,
          base_path: "/hat-rates",
        )
      end

      before do
        FactoryGirl.create(:redirect_draft_content_item,
          base_path: "/hat-rates",
        )
      end

      it "publishes the redirect already created, from the old location to the new location" do
        described_class.call(payload)

        redirect = Edition.joins(:document).find_by(
          base_path: "/hat-rates",
          documents: { locale: "en" },
          state: "published",
        )

        expect(redirect).to be_present
        expect(redirect.schema_name).to eq("redirect")
      end

      it "supersedes the previously published item" do
        described_class.call(payload)

        updated_item = Edition.find(live_item.id)
        expect(updated_item.state).to eq("superseded")
      end
    end

    context "when an access limit is set on the draft content item" do
      before do
        FactoryGirl.create(:access_limit, content_item: draft_item)
      end

      it "destroys the access limit" do
        expect {
          described_class.call(payload)
        }.to change(AccessLimit, :count).by(-1)

        expect(AccessLimit.exists?(content_item: draft_item)).to eq(false)
      end
    end

    context "when given an invalid update_type" do
      before do
        payload[:update_type] = "invalid"
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "An update_type of 'invalid' is invalid")
      end
    end

    context "when no draft exists to publish" do
      before do
        draft_item.destroy
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /does not exist/)
      end

      context "but a published item does exist" do
        before do
          FactoryGirl.create(:live_content_item,
            document: document,
            base_path: base_path,
          )
        end

        it "raises an error to indicate it has already been published" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /already published content item/)
        end
      end
    end

    it_behaves_like TransactionalCommand
  end

  context "for a pathless content item format" do
    let(:pathless_content_item) do
      FactoryGirl.create(:draft_content_item,
        document_type: "contact",
        user_facing_version: 2,
        base_path: nil,
      )
    end

    let(:payload) do
      {
        content_id: pathless_content_item.content_id,
        update_type: "major",
        previous_version: 1,
      }
    end

    context "with no Location" do
      it "publishes the item" do
        described_class.call(payload)

        updated_item = Edition.find(pathless_content_item.id)
        expect(updated_item.state).to eq("published")
      end

      context "with a previously published item" do
        let!(:live_content_item) do
          FactoryGirl.create(:live_content_item,
            document: pathless_content_item.document,
            document_type: "contact",
            user_facing_version: 1,
          )
        end

        it "publishes the draft" do
          described_class.call(payload)

          updated_item = Edition.find(pathless_content_item.id)
          expect(updated_item.state).to eq("published")
        end
      end
    end
  end
end
