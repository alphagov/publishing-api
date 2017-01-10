require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    let(:validator) do
      instance_double(SchemaValidator, valid?: true, errors: [])
    end

    before do
      allow(SchemaValidator).to receive(:new).and_return(validator)
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }

    let(:payload) do
      {
        content_id: content_id,
        base_path: base_path,
        update_type: "major",
        title: "Some Title",
        publishing_app: "publisher",
        rendering_app: "frontend",
        document_type: "guide",
        schema_name: "guide",
        locale: locale,
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note: { note: "Info", public_timestamp: Time.now.utc.to_s }
      }
    end

    it "sends to the downstream draft worker" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(:content_id, :locale, :payload_version, update_dependencies: true),
        )

      described_class.call(payload)
    end

    it "does not send to the downstream publish worker" do
      expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)
      described_class.call(payload)
    end

    it "creates an action" do
      expect(Action.count).to be 0
      described_class.call(payload)
      expect(Action.count).to be 1
      expect(Action.first.attributes).to match a_hash_including(
        "content_id" => content_id,
        "locale" => locale,
        "action" => "PutContent",
      )
    end

    context "when the 'downstream' parameter is false" do
      it "does not send to the downstream draft worker" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)

        described_class.call(payload, downstream: false)
      end
    end

    context "when the 'bulk_publishing' flag is set" do
      it "enqueues in the correct queue" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_low",
            anything
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
        }.to raise_error(CommandError, /is already reserved/i)
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
        expect(content_item.state).to eq("draft")
        expect(content_item.content_store).to eq("draft")
        expect(LockVersion.find_by!(target: content_item).number).to eq(3)
      end

      it "creates the draft's user-facing version using the live's user-facing version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(content_item.state).to eq("draft")
        expect(content_item.user_facing_version).to eq(6)
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

          expect(ContentItem.where(base_path: "/moved", state: "draft")).to exist
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = ContentItem.find_by(
            base_path: base_path,
            state: "draft",
          )

          expect(redirect).to be_present
          expect(redirect.schema_name).to eq("redirect")
          expect(redirect.publishing_app).to eq("publisher")

          expect(redirect.redirects).to eq([{
            path: base_path,
            type: "exact",
            destination: "/moved",
          }])
        end

        it "sends a create request to the draft content store for the redirect" do
          allow(Presenters::ContentStorePresenter).to receive(:present).and_return(base_path: base_path)
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).twice

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
            expect(content_item.locale).to eq("fr")
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

          regex = /user_facing_version=(\d+) and locale=en for content item=#{Regexp.quote(content_id)} conflicts/

          thread1 = Thread.new { described_class.call(payload) }
          thread2 = Thread.new { described_class.call(payload) }
          thread1.join
          thread2.join

          expect(ContentItem.all.pluck(:state)).to eq %w(superseded published draft)
        end
      end
    end

    context "when creating a draft for a previously unpublished content item" do
      before do
        FactoryGirl.create(:unpublished_content_item,
          content_id: content_id,
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
        expect(content_item.state).to eq("draft")
        expect(LockVersion.find_by!(target: content_item).number).to eq(3)
      end

      it "creates the draft's user-facing version using the unpublished user-facing version as a starting point" do
        described_class.call(payload)

        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(content_item.state).to eq("draft")
        expect(content_item.user_facing_version).to eq(6)
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

    context "when the payload is for a brand new content item" do
      it "creates a content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        expect(content_item).to be_present
        expect(content_item.content_id).to eq(content_id)
        expect(content_item.title).to eq("Some Title")
      end

      it "sets a draft state for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        expect(content_item.state).to eq("draft")
      end

      it "sets a user-facing version of 1 for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        expect(content_item.user_facing_version).to eq(1)
      end

      it "creates a lock version for the content item" do
        described_class.call(payload)
        content_item = ContentItem.last

        lock_version = LockVersion.find_by!(target: content_item)
        expect(lock_version.number).to eq(1)
      end

      it "creates a change note" do
        expect { described_class.call(payload) }.
          to change { ChangeNote.count }.by(1)
      end
    end

    context "when the payload is for an already drafted content item" do
      let!(:previously_drafted_item) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          title: "Old Title",
          lock_version: 1,
          publishing_app: "publisher",
        )
      end

      it "updates the content item" do
        described_class.call(payload)
        previously_drafted_item.reload

        expect(previously_drafted_item.title).to eq("Some Title")
      end

      it "keeps the content_store as draft" do
        described_class.call(payload)
        previously_drafted_item.reload

        expect(previously_drafted_item.content_store).to eq("draft")
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

        expect(previously_drafted_item.user_facing_version).to eq(1)
      end

      it "increments the lock version for the content item" do
        described_class.call(payload)
        previously_drafted_item.reload

        lock_version = LockVersion.find_by!(target: previously_drafted_item)
        expect(lock_version.number).to eq(2)
      end

      context "when the base path has changed" do
        before do
          previously_drafted_item.update_attributes!(
            routes: [{ path: "/old-path", type: "exact" }, { path: "/old-path.atom", type: "exact" }],
            base_path: "/old-path",
          )
        end

        it "updates the location's base path" do
          described_class.call(payload)
          previously_drafted_item.reload

          expect(previously_drafted_item.base_path).to eq("/vat-rates")
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = ContentItem.find_by(
            base_path: "/old-path",
            state: "draft",
          )

          expect(redirect).to be_present
          expect(redirect.schema_name).to eq("redirect")
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
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).twice

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

            expect(content_item.locale).to eq("fr")
          end
        end

        context "when there is a draft at the new base path" do
          let!(:substitute_item) do
            FactoryGirl.create(:draft_content_item,
              content_id: SecureRandom.uuid,
              base_path: base_path,
              title: "Substitute Content",
              lock_version: 1,
              publishing_app: "publisher",
              document_type: "coming_soon",
            )
          end

          it "deletes the substitute item" do
            described_class.call(payload)
            expect(ContentItem.exists?(id: substitute_item.id)).to eq(false)
          end

          context "conflicting version" do
            before do
              lock_version = LockVersion.find_by!(target: previously_drafted_item)
              lock_version.update_attributes!(number: 2)

              payload.merge!(previous_version: 1)
            end

            it "doesn't delete the substitute item" do
              expect {
                described_class.call(payload)
              }.to raise_error(CommandError, /Conflict/)
              expect(ContentItem.exists?(id: substitute_item.id)).to eq(true)
            end
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

          expect(content_item.redirects).to eq([])
          expect(content_item.phase).to eq("live")
          expect(content_item.locale).to eq("en")
        end
      end

      context "when the previous draft has an access limit" do
        let!(:access_limit) do
          FactoryGirl.create(:access_limit, content_item: previously_drafted_item, users: ["old-user"])
        end

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

    context 'without a publishing_app' do
      before do
        payload.delete(:publishing_app)
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /publishing_app is required/)
      end
    end

    it_behaves_like TransactionalCommand

    context "when the draft does not exist" do
      context "with a provided last_edited_at" do
        it "stores the provided timestamp" do
          last_edited_at = 1.year.ago

          described_class.call(payload.merge(
                                 last_edited_at: last_edited_at
                              ))

          content_item = ContentItem.last

          expect(content_item.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          content_item = ContentItem.last

          expect(content_item.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end
    end

    context "when the draft does exist" do
      let!(:content_item) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
        )
      end

      context "with a provided last_edited_at" do
        %w(minor major republish).each do |update_type|
          context "with update_type of #{update_type}" do
            it "stores the provided timestamp" do
              last_edited_at = 1.year.ago

              described_class.call(payload.merge(
                                     update_type: update_type,
                                     last_edited_at: last_edited_at
                                   ))

              content_item.reload

              expect(content_item.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
            end
          end
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          content_item.reload

          expect(content_item.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end

      context "when other update type" do
        it "dosen't change last_edited_at" do
          old_last_edited_at = content_item.last_edited_at

          described_class.call(payload.merge(
                                 update_type: "republish"
                               ))

          content_item.reload

          expect(content_item.last_edited_at).to eq(old_last_edited_at)
        end
      end
    end

    context "with a pathless content item payload" do
      before do
        payload.delete(:base_path)
        payload[:schema_name] = "contact"
      end

      it "saves the content as draft" do
        expect {
          described_class.call(payload)
        }.to change(ContentItem, :count).by(1)
      end

      it "sends to the downstream draft worker" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        described_class.call(payload)
      end

      context "for an existing draft content item" do
        let!(:draft_content_item) do
          FactoryGirl.create(:draft_content_item, content_id: content_id, title: "Old Title")
        end

        it "updates the draft" do
          described_class.call(payload)
          expect(draft_content_item.reload.title).to eq("Some Title")
        end
      end

      context "for an existing live content item" do
        let!(:live_content_item) do
          FactoryGirl.create(:live_content_item, content_id: content_id, title: "Old Title")
        end

        it "creates a new draft" do
          expect {
            described_class.call(payload)
          }.to change(ContentItem, :count).by(1)
        end
      end
    end

    context "where a base_path is optional and supplied" do
      before do
        payload.merge!(
          schema_name: "contact",
          document_type: "contact",
          previous_version: 2,
        )
      end

      it "sends to the content-store" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        described_class.call(payload)
      end

      # This covers a specific edge case where the content item uniqueness validator
      # matched anything else with the same state, locale and version because it
      # was previously ignoring the base path, now it should return without
      # attempting to validate for pathless formats.
      context "with other similar pathless items" do
        before do
          FactoryGirl.create(:draft_content_item,
            content_id: SecureRandom.uuid,
            base_path: nil,
            schema_name: "contact",
            document_type: "contact",
            locale: "en",
            user_facing_version: 3,
          )
        end

        it "doesn't conflict" do
          expect {
            described_class.call(payload)
          }.not_to raise_error
        end
      end

      context "when there's a conflicting content item" do
        before do
          FactoryGirl.create(:draft_content_item,
            content_id: content_id,
            base_path: base_path,
            schema_name: "contact",
            document_type: "contact",
            locale: "en",
            user_facing_version: 3,
          )
        end

        it "conflicts" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Conflict/)
        end
      end
    end

    context "schema validation fails" do
      let(:errors) do
        [{ schema: "a", fragment: "b", message: "c", failed_attribute: "d" }]
      end
      let(:validator) do
        instance_double(SchemaValidator, valid?: false, errors: errors)
      end

      it "raises command error and exits" do
        expect(PathReservation).not_to receive(:reserve_base_path!)
        expect { described_class.call(payload) }.to raise_error { |error|
          expect(error).to be_a(CommandError)
          expect(error.code).to eq 422
          expect(error.error_details).to eq errors
        }
      end
    end

    context "schema validation passes" do
      it "returns success" do
        expect(PathReservation).to receive(:reserve_base_path!)
        expect { described_class.call(payload) }.not_to raise_error
      end
    end
  end
end
