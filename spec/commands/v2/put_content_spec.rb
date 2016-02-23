require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }

    let(:payload) {
      {
        content_id: content_id,
        base_path: base_path,
        title: "Some Title",
        publishing_app: "publisher",
        rendering_app: "frontend",
        format: "guide",
        locale: locale,
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
      }
    }

    it "sends to the draft content store" do
      expect(ContentStoreWorker).to receive(:perform_in)
        .with(
          1.second,
          content_store: Adapters::DraftContentStore,
          content_item_id: anything,
        )

      described_class.call(payload)
    end

    it "does not send the content item on the message queue" do
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
      described_class.call(payload)
    end

    it "does not send to the live content store" do
      expect(ContentStoreWorker).not_to receive(:perform_in)
        .with(
          content_store: Adapters::ContentStore,
          content_item_id: anything,
        )

      described_class.call(payload)
    end

    context "when the 'downstream' parameter is false" do
      it "does not send any requests to any content store" do
        expect(ContentStoreWorker).not_to receive(:perform_in)
        described_class.call(payload, downstream: false)
      end
    end

    context "when there are no previous path reservations" do
      it "creates a path reservation" do
        expect {
          described_class.call(payload)
        }.to change(PathReservation, :count).by(1)

        reservation = PathReservation.last
        expect(reservation.base_path).to eq("/vat-rates")
        expect(reservation.publishing_app).to eq("publisher")
      end
    end

    context "when the base path has been reserved by another publishing app" do
      before do
        FactoryGirl.create(:path_reservation, base_path: "/vat-rates", publishing_app: "something-else")
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /is already registered/i)
      end
    end

    context "when creating a draft for a previously published content item" do
      before do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          lock_version: 2,
          user_facing_version: 5,
        )
      end

      it "creates the draft's lock version using the live's lock version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(LockVersion.find_by!(target: content_item).number).to eq(3)
      end

      it "creates the draft's user-facing version using the live's user-facing version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(UserFacingVersion.find_by!(content_item: content_item).number).to eq(6)
      end
    end

    context "with another draft content item blocking the put_content action" do
      let!(:other_content_item) {
        FactoryGirl.create(:redirect_draft_content_item,
          locale: locale,
          base_path: base_path,
        )
      }

      it "withdraws the content item which is in the way" do
        described_class.call(payload)

        state = State.find_by!(content_item: other_content_item)
        expect(state.name).to eq("withdrawn")

        translation = Translation.find_by!(content_item: other_content_item)
        expect(translation.locale).to eq(locale)

        location = Location.find_by!(content_item: other_content_item)
        expect(location.base_path).to eq(base_path)
      end
    end

    context "with another draft content item not blocking the put_content action" do
      let(:new_locale) { "fr" }

      let!(:other_content_item) {
        FactoryGirl.create(:redirect_draft_content_item,
          locale: new_locale,
          base_path: base_path,
        )
      }

      it "does not withdraw the content item" do
        described_class.call(payload)

        state = State.find_by!(content_item: other_content_item)
        expect(state.name).to eq("draft")

        translation = Translation.find_by!(content_item: other_content_item)
        expect(translation.locale).to eq(new_locale)

        location = Location.find_by!(content_item: other_content_item)
        expect(location.base_path).to eq(base_path)
      end
    end

    context "when the payload is for a brand new content item" do
      it "creates a content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(content_item.title).to eq("Some Title")
      end

      it "creates a state for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        state = State.find_by!(content_item: content_item)
        expect(state.name).to eq("draft")
      end

      it "creates a user-facing version for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        user_facing_version = UserFacingVersion.find_by!(content_item: content_item)
        expect(user_facing_version.number).to eq(1)
      end

      it "creates a lock version for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        lock_version = LockVersion.find_by!(target: content_item)
        expect(lock_version.number).to eq(1)
      end

      it "creates a translation for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        translation = Translation.find_by!(content_item: content_item)
        expect(translation.locale).to eq("en")
      end

      it "creates a location for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        location = Location.find_by!(content_item: content_item)
        expect(location.base_path).to eq(base_path)
      end
    end

    context "when the payload is for an already drafted content item" do
      let!(:previously_drafted_item) {
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          title: "Old Title",
          lock_version: 1,
          publishing_app: "publisher",
        )
      }

      it "updates the content item" do
        described_class.call(payload)
        previously_drafted_item.reload

        expect(previously_drafted_item.title).to eq("Some Title")
      end

      it "does not increment the user-facing version for the content item" do
        described_class.call(payload)
        previously_drafted_item.reload

        user_facing_version = UserFacingVersion.find_by!(content_item: previously_drafted_item)
        expect(user_facing_version.number).to eq(1)
      end

      it "increments the lock version for the content item" do
        described_class.call(payload)
        previously_drafted_item.reload

        lock_version = LockVersion.find_by!(target: previously_drafted_item)
        expect(lock_version.number).to eq(2)
      end

      context "when the base path has changed" do
        let(:previous_location) { Location.find_by!(content_item: previously_drafted_item) }

        before do
          previously_drafted_item.update_attributes!(
            routes: [{ path: "/old-path", type: "exact" }],
          )
          previous_location.update_attributes!(base_path: "/old-path")
        end

        it "updates the location's base path" do
          described_class.call(payload)
          previous_location.reload

          expect(previous_location.base_path).to eq("/vat-rates")
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = ContentItemFilter.filter(
            base_path: "/old-path",
            state: "draft",
          ).first

          expect(redirect).to be_present
          expect(redirect.format).to eq("redirect")
          expect(redirect.publishing_app).to eq("publisher")

          expect(redirect.redirects).to eq([
            {
              path: "/old-path",
              type: "exact",
              destination: "/vat-rates",
            }
          ])
        end

        it "sends a create request to the draft content store for the redirect" do
          allow(ContentStoreWorker).to receive(:perform_in)
            .with(
              1.second,
              content_store: Adapters::DraftContentStore,
              content_item_id: anything,
            )

          expect(ContentStoreWorker).to receive(:perform_in)
            .with(
              1.second,
              content_store: Adapters::DraftContentStore,
              content_item_id: anything,
            )

          described_class.call(payload)
        end

        context "when the locale differs from the existing draft content item" do
          before do
            payload.merge!(locale: "fr", title: "French Title")
          end

          it "creates a separate draft content item in the given locale" do
            described_class.call(payload)
            expect(ContentItem.count).to eq(2)

            content_item = ContentItem.last
            expect(content_item.title).to eq("French Title")

            translation = Translation.find_by!(content_item: content_item)
            expect(translation.locale).to eq("fr")
          end
        end
      end

      context "with a 'previous_version' which does not match the current lock_version of the draft item" do
        before do
          lock_version = LockVersion.find_by!(target: previously_drafted_item)
          lock_version.update_attributes!(number: 2)

          payload.merge!(previous_version: 1)
        end

        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Conflict/)
        end
      end

      context "when some of the attributes are not provided in the payload" do
        before do
          payload.delete(:redirects)
          payload.delete(:phase)
          payload.delete(:locale)
        end

        it "resets those attributes to their defaults from the database" do
          described_class.call(payload)
          content_item = ContentItem.last
          translation = Translation.find_by!(content_item: content_item)

          expect(content_item.redirects).to eq([])
          expect(content_item.phase).to eq("live")
          expect(translation.locale).to eq("en")
        end
      end

      context "when the previous draft has an access limit" do
        let!(:access_limit) {
          FactoryGirl.create(:access_limit, content_item: previously_drafted_item, users: ["old-user"])
        }

        context "when the params includes an access limit" do
          before do
            payload.merge!(access_limited: { users: ["new-user"] })
          end

          it "updates the existing access limit" do
            described_class.call(payload)
            access_limit.reload

            expect(access_limit.users).to eq(["new-user"])
          end
        end

        context "when the params does not include an access limit" do
          it "deletes the existing access limit" do
            expect {
              described_class.call(payload)
            }.to change(AccessLimit, :count).by(-1)
          end
        end
      end

      context "when the previously drafted item does not have an access limit" do
        context "when the params includes an access limit" do
          before do
            payload.merge!(access_limited: { users: ["new-user"] })
          end

          it "creates a new access limit" do
            expect {
              described_class.call(payload)
            }.to change(AccessLimit, :count).by(1)

            access_limit = AccessLimit.find_by!(content_item: previously_drafted_item)
            expect(access_limit.users).to eq(["new-user"])
          end
        end
      end
    end

    context "when the params includes an access limit" do
      before do
        payload.merge!(access_limited: { users: ["new-user"] })
      end

      it "creates a new access limit" do
        expect {
          described_class.call(payload)
        }.to change(AccessLimit, :count).by(1)

        access_limit = AccessLimit.last
        expect(access_limit.users).to eq(["new-user"])
        expect(access_limit.content_item).to eq(ContentItem.last)
      end
    end

    context "when the 'links' parameter is provided" do
      before do
        payload.merge!(links: { users: ["new-user"] })
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /'links' parameter should not be provided/)
      end
    end

    it_behaves_like TransactionalCommand
  end
end
