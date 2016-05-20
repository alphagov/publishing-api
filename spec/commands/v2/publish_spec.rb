require "rails_helper"

RSpec.describe Commands::V2::Publish do
  describe "call" do
    let(:base_path) { "/vat-rates" }

    let!(:draft_item) do
      FactoryGirl.create(
        :draft_content_item,
        content_id: content_id,
        lock_version: 2,
        base_path: base_path,
      )
    end

    let!(:linkable) {
      FactoryGirl.create(:linkable,
        content_item: draft_item,
        base_path: base_path,
        state: "draft",
      )
    }

    let(:expected_content_store_payload) { { base_path: base_path } }
    let(:content_id) { SecureRandom.uuid }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})

      allow(DependencyResolutionWorker).to receive(:perform_async)
      allow(Presenters::ContentStorePresenter).to receive(:present)
        .and_return(expected_content_store_payload)
      allow(GdsApi::GovukHeaders).to receive(:headers)
        .and_return(govuk_request_id: "12345-67890")
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    let(:payload) do
      {
        content_id: content_id,
        update_type: "major",
        previous_version: 2,
      }
    end

    it "sets the linkable to 'published'" do
      described_class.call(payload)
      linkable.reload
      expect(linkable.state).to eq("published")
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
          expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
            .with(hash_including(update_type: "major"))

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
      let!(:live_item) do
        FactoryGirl.create(:live_content_item,
          content_id: draft_item.content_id,
          base_path: base_path,
        )
      end

      it "marks the previously published item as 'superseded'" do
        described_class.call(payload)

        state = State.find_by!(content_item: live_item)
        expect(state.name).to eq("superseded")
      end
    end

    context "with another content item blocking the publish action" do
      let(:draft_locale) { Translation.find_by!(content_item: draft_item).locale }

      let!(:other_content_item) {
        FactoryGirl.create(:redirect_live_content_item,
          locale: draft_locale,
          base_path: base_path,
        )
      }

      it "unpublishes the content item which is in the way" do
        described_class.call(payload)

        state = State.find_by!(content_item: other_content_item)
        expect(state.name).to eq("unpublished")

        translation = Translation.find_by!(content_item: other_content_item)
        expect(translation.locale).to eq(draft_locale)

        location = Location.find_by!(content_item: other_content_item)
        expect(location.base_path).to eq(base_path)
      end
    end

    context "with another content item not blocking the publish action" do
      let(:new_locale) { "fr" }

      let!(:other_content_item) {
        FactoryGirl.create(
          :redirect_live_content_item,
          locale: new_locale,
          base_path: base_path,
        )
      }

      it "does not unpublish the content item" do
        described_class.call(payload)

        state = State.find_by!(content_item: other_content_item)
        expect(state.name).to eq("published")

        translation = Translation.find_by!(content_item: other_content_item)
        expect(translation.locale).to eq(new_locale)

        location = Location.find_by!(content_item: other_content_item)
        expect(location.base_path).to eq(base_path)
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

        state = State.find_by!(content_item: draft_item)
        expect(state.name).to eq("published")
      end

      it "sends a payload downstream asynchronously" do
        expect(PresentedContentStoreWorker)
          .to receive(:perform_async)
          .with(
            content_store: Adapters::ContentStore,
            payload: a_hash_including(:content_item_id, :payload_version),
            request_uuid: "12345-67890",
          )

        described_class.call(payload)
      end

      it "presents the content item for the downstream request" do
        expect(Presenters::ContentStorePresenter).to receive(:present)
          .with(draft_item, an_instance_of(Fixnum), fallback_order: [:published])

        described_class.call(payload)
      end

      context "when the 'downstream' parameter is false" do
        it "does not send any requests to any content store" do
          expect(PresentedContentStoreWorker).not_to receive(:perform_async)
          described_class.call(payload, downstream: false)
        end

        it "does not send any messages on the message queue" do
          expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
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
          let(:public_updated_at_from_last_live_item) { Time.zone.now - 2.years }

          let!(:live_item) do
            FactoryGirl.create(:live_content_item,
              content_id: draft_item.content_id,
              public_updated_at: public_updated_at_from_last_live_item,
              base_path: base_path,
            )
          end

          before do
            payload.merge!(update_type: "minor")
          end

          it "preserves the public_updated_at value from the last live item" do
            expect(PresentedContentStoreWorker)
              .to receive(:perform_async)
              .with(
                content_store: Adapters::ContentStore,
                payload: a_hash_including(:content_item_id, :payload_version),
                request_uuid: "12345-67890",
              )

            described_class.call(payload)

            expect(ContentItem.last.public_updated_at.iso8601).to eq(public_updated_at_from_last_live_item.iso8601)
          end
        end

        context "for a republish" do
          let(:public_updated_at) { Time.zone.now - 1.year }

          before do
            draft_item.update_attributes!(public_updated_at: public_updated_at)
            payload.merge!(update_type: "republish")
          end

          it "uses the stored timestamp for major or minor" do
            expect(PresentedContentStoreWorker)
              .to receive(:perform_async)
              .with(
                content_store: Adapters::ContentStore,
                payload: a_hash_including(:content_item_id, :payload_version),
                request_uuid: "12345-67890",
              )

            described_class.call(payload)
          end
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
          content_id: draft_item.content_id,
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

        redirect = ContentItemFilter.filter(
          base_path: "/hat-rates",
          locale: "en",
          state: "published",
        ).first

        expect(redirect).to be_present
        expect(redirect.format).to eq("redirect")
      end

      it "unpublishes the previously published item" do
        described_class.call(payload)

        state = State.find_by!(content_item: live_item)
        expect(state.name).to eq("unpublished"),
          "If this is failing because the content item has been superseded,
          check that unpublishing is happening before superseding."
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
            content_id: content_id,
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

    context "for a previously unpublished item" do
      let!(:unpublished_item) do
        FactoryGirl.create(:content_item,
          content_id: content_id,
          state: "published",
          lock_version: 2,
          base_path: base_path,
        )
      end

      let!(:unpublishing) do
        FactoryGirl.create(:unpublishing, content_item: unpublished_item)
      end

      it "removes the unpublishing" do
        expect {
          described_class.call(payload)
        }.to change(Unpublishing, :count).by(-1)

        expect(Unpublishing.find_by(content_item: unpublished_item)).to be nil
      end
    end

    it_behaves_like TransactionalCommand
  end
end
