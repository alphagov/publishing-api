require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
      allow(GdsApi::GovukHeaders).to receive(:headers)
        .and_return(govuk_request_id: "12345-67890")
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
      expect(PresentedContentStoreWorker).to receive(:perform_async_in_queue)
        .with(
          "content_store_high",
          content_store: Adapters::DraftContentStore,
          payload: a_hash_including(:content_item_id, :payload_version),
          request_uuid: "12345-67890",
        )

      described_class.call(payload)
    end

    it "enqueues the dependencies lookup" do
      expect(DependencyResolutionWorker).to receive(:perform_async)
        .with(
          content_store: Adapters::DraftContentStore,
          fields: anything,
          content_id: anything,
          request_uuid: "12345-67890",
          payload_version: instance_of(Fixnum)
        )

      described_class.call(payload)
    end

    it "does not send the content item on the message queue" do
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
      described_class.call(payload)
    end

    it "does not send to the live content store" do
      expect(PresentedContentStoreWorker).not_to receive(:perform_async_in_queue)
        .with(
          "content_store_high",
          content_store: Adapters::ContentStore,
          payload: a_hash_including(:content_item_id, :payload_version),
        )

      described_class.call(payload)
    end

    context "when the 'downstream' parameter is false" do
      it "does not send any requests to any content store" do
        expect(PresentedContentStoreWorker).not_to receive(:perform_async_in_queue)

        described_class.call(payload, downstream: false)
      end
    end

    context "when the 'bulk_publishing' flag is set" do
      it "enqueues in the correct queue" do
        expect(PresentedContentStoreWorker).to receive(:perform_async_in_queue)
          .with(
            "content_store_low",
            content_store: Adapters::DraftContentStore,
            payload: a_hash_including(:content_item_id, :payload_version),
            request_uuid: "12345-67890",
          )

        described_class.call(payload.merge(bulk_publishing: true))
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
        FactoryGirl.create(:path_reservation,
          base_path: base_path,
          publishing_app: "something-else"
        )
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /is already registered/i)
      end
    end

    context "when creating a draft for a previously published content item" do
      let(:first_published_at) { 1.year.ago }

      before do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          lock_version: 2,
          user_facing_version: 5,
          first_published_at: first_published_at,
          base_path: base_path,
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

      it "copies over the first_published_at timestamp" do
        described_class.call(payload)

        content_item = ContentItem.last
        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)

        expect(content_item.first_published_at.iso8601).to eq(first_published_at.iso8601)
      end

      context "and the base path has changed" do
        before do
          payload.merge!(
            base_path: "/moved",
            routes: [{ path: "/moved", type: "exact" }],
          )
        end

        it "sets the correct base path on the location" do
          described_class.call(payload)

          content_item = ContentItemFilter.filter(
            base_path: "/moved",
            state: "draft",
          ).first

          location = Location.find_by!(content_item: content_item)

          expect(location.base_path).to eq("/moved")
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = ContentItemFilter.filter(
            base_path: base_path,
            state: "draft",
          ).first

          expect(redirect).to be_present
          expect(redirect.format).to eq("redirect")
          expect(redirect.publishing_app).to eq("publisher")

          expect(redirect.redirects).to eq([{
            path: base_path,
            type: "exact",
            destination: "/moved",
          }])
        end

        it "sends a create request to the draft content store for the redirect" do
          allow(Presenters::ContentStorePresenter).to receive(:present).and_return(base_path: base_path)
          expect(PresentedContentStoreWorker).to receive(:perform_async_in_queue)
            .with(
              "content_store_high",
              content_store: Adapters::DraftContentStore,
              payload: a_hash_including(:content_item_id, :payload_version),
              request_uuid: "12345-67890",
            ).twice

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

      describe "race conditions", skip_cleaning: true do
        after do
          DatabaseCleaner.clean_with :truncation
        end

        it "copes with race conditions" do
          described_class.call(payload)
          Commands::V2::Publish.call(content_id: content_id, update_type: "minor")

          expect {
            thread1 = Thread.new { described_class.call(payload) }
            thread2 = Thread.new { described_class.call(payload) }
            thread1.join
            thread2.join
          }.to raise_error(CommandError, /conflicts with a duplicate/)

          expect(State.all.pluck(:name)).to eq %w(superseded published draft)
        end
      end
    end

    context "when creating a draft for a previously unpublished content item" do
      before do
        FactoryGirl.create(:content_item,
          content_id: content_id,
          state: "unpublished",
          lock_version: 2,
          user_facing_version: 5,
          base_path: base_path,
        )
      end

      it "creates the draft's lock version using the unpublished lock version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(LockVersion.find_by!(target: content_item).number).to eq(3)
      end

      it "creates the draft's user-facing version using the unpublished user-facing version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(UserFacingVersion.find_by!(content_item: content_item).number).to eq(6)
      end

      it "allows the setting of first_published_at" do
        explicit_first_published = DateTime.new(2016, 05, 23, 1, 1, 1).rfc3339
        payload[:first_published_at] = explicit_first_published

        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(content_item.first_published_at).to eq(explicit_first_published)
      end
    end

    context "when creating a draft when there are multiple unpublished and published items" do
      before do
        FactoryGirl.create(:content_item,
          content_id: content_id,
          state: "unpublished",
          lock_version: 2,
          user_facing_version: 5,
          base_path: base_path,
        )

        FactoryGirl.create(:content_item,
          content_id: content_id,
          state: "published",
          lock_version: 3,
          user_facing_version: 8,
          base_path: base_path,
        )

        FactoryGirl.create(:content_item,
          content_id: content_id,
          state: "unpublished",
          lock_version: 5,
          user_facing_version: 6,
          base_path: base_path,
        )
      end

      it "creates the draft's lock version from the item with the latest user-facing version" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(LockVersion.find_by!(target: content_item).number).to eq(4)
      end

      it "creates the draft's user-facing version from the item with the latest user-facing version" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(State.find_by!(content_item: content_item).name).to eq("draft")
        expect(UserFacingVersion.find_by!(content_item: content_item).number).to eq(9)
      end
    end

    context "with another draft content item blocking the put_content action" do
      let!(:other_content_item) {
        FactoryGirl.create(:redirect_draft_content_item,
          locale: locale,
          base_path: base_path,
        )
      }

      it "unpublishes the content item which is in the way" do
        described_class.call(payload)

        state = State.find_by!(content_item: other_content_item)
        expect(state.name).to eq("unpublished")

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

      it "does not unpublish the content item" do
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

      it "creates a linkable for the content item" do
        described_class.call(payload)

        content_item = ContentItem.last

        linkable = Linkable.find_by!(content_item: content_item)
        expect(linkable.base_path).to eq(base_path)
        expect(linkable.state).to eq("draft")
        expect(linkable.document_type).to eq(content_item.document_type)
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

      it "keeps the first_published_at timestamp if present" do
        first_published_at = 1.year.ago
        previously_drafted_item.update_attributes(first_published_at: first_published_at)

        described_class.call(payload)
        previously_drafted_item.reload

        expect(previously_drafted_item.first_published_at).to be_present
        expect(previously_drafted_item.first_published_at.iso8601).to eq(first_published_at.iso8601)
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

      it "does not create a new linkable" do
        expect {
          described_class.call(payload)
        }.not_to change {
          Linkable.count
        }
      end

      context "when the base path has changed" do
        let(:previous_location) { Location.find_by!(content_item: previously_drafted_item) }

        before do
          previously_drafted_item.update_attributes!(
            routes: [{ path: "/old-path", type: "exact" }, { path: "/old-path.atom", type: "exact" }],
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
              destination: base_path
            }, {
              path: "/old-path.atom",
              type: "exact",
              destination: "#{base_path}.atom"
            }
          ])
        end

        it "sends a create request to the draft content store for the redirect" do
          allow(Presenters::ContentStorePresenter).to receive(:present).and_return(base_path: "/vat-rates")
          expect(PresentedContentStoreWorker).to receive(:perform_async_in_queue)
            .with(
              "content_store_high",
              content_store: Adapters::DraftContentStore,
              payload: a_hash_including(:content_item_id, :payload_version),
              request_uuid: "12345-67890",
            ).twice

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

    context "when a link set does not exist for the content id" do
      it "creates an empty link set" do
        expect {
          described_class.call(payload)
        }.to change(LinkSet, :count).by(1)

        link_set = LinkSet.last

        expect(link_set.content_id).to eq(content_id)
        expect(link_set.links).to be_empty
      end

      it "creates a lock version for the link set" do
        expect {
          described_class.call(payload)
        }.to change(LinkSet, :count).by(1)

        link_set = LinkSet.last
        lock_version = LockVersion.find_by(target: link_set)

        expect(lock_version).to be_present
        expect(lock_version.number).to eq(1)
      end
    end

    context "when a link set exists for the content id" do
      let(:link_target) { SecureRandom.uuid }

      let!(:link_set) do
        FactoryGirl.create(:link_set,
          content_id: content_id,
          links: [
            FactoryGirl.create(:link,
              link_type: "parent",
              target_content_id: link_target,
            )
          ]
        )
      end

      it "does not affect the link set" do
        expect {
          described_class.call(payload)
        }.not_to change(LinkSet, :count)

        links = link_set.reload.links
        expect(links.count).to eq(1)

        expect(links.first.link_type).to eq("parent")
        expect(links.first.target_content_id).to eq(link_target)
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

    context "without a base_path" do
      before do
        payload.delete(:base_path)
      end

      context "when schema requires a base_path" do
        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Base path is not a valid absolute URL path/)
        end
      end

      context "when schema does not require a base_path" do
        before do
          allow(Presenters::ContentStorePresenter).to receive(:present)
            .and_return(base_path: "/vat-rates")

          payload.merge!(schema_name: 'government', document_type: 'government').delete(:format)
        end

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

    it_behaves_like TransactionalCommand

    it "validate against schema" do
      allow(SchemaValidator).to receive(:new).and_return(double('validator', validate: true))
      expect(SchemaValidator).to receive(:new)
        .with(a_hash_including(format: "guide"), type: :schema)

      described_class.call(payload)
    end
  end
end
