require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  include IntegrationSpecHelper

  describe "call" do
    let(:payload) { default_payload }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when creating a draft for a previously published edition" do
      let(:first_published_at) { 1.year.ago }

      let(:document) do
        FactoryGirl.create(
          :document,
          content_id: content_id,
          stale_lock_version: 5,
        )
      end

      let!(:edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          user_facing_version: 5,
          first_published_at: first_published_at,
          base_path: base_path,
        )
      end

      let!(:link) do
        edition.links.create(link_type: "test",
                             target_content_id: document.content_id)
      end

      it "creates the draft's user-facing version using the live's user-facing version as a starting point" do
        described_class.call(payload)

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.user_facing_version).to eq(6)
      end

      it "copies over the first_published_at timestamp" do
        described_class.call(payload)

        edition = Edition.last
        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)

        expect(edition.first_published_at.iso8601).to eq(first_published_at.iso8601)
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

          expect(Edition.where(base_path: "/moved", state: "draft")).to exist
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = Edition.find_by(
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
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).twice

          described_class.call(payload)
        end

        context "when the locale differs from the existing draft edition" do
          before do
            payload.merge!(locale: "fr", title: "French Title")
          end

          it "creates a separate draft edition in the given locale" do
            described_class.call(payload)
            expect(Edition.count).to eq(2)

            edition = Edition.last
            expect(edition.title).to eq("French Title")
            expect(edition.document.locale).to eq("fr")
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

          thread1 = Thread.new { described_class.call(payload) }
          thread2 = Thread.new { described_class.call(payload) }
          thread1.join
          thread2.join

          expect(Edition.all.pluck(:state)).to match_array(%w(superseded published draft))
        end
      end
    end
  end
end
