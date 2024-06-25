RSpec.describe Presenters::EditionPresenter do
  let(:present_drafts) { false }
  let(:change_history) { { note: "Note", public_timestamp: 1.day.ago.to_s } }
  let(:details) { { body: "<p>Text</p>\n", change_history: [change_history] } }
  let(:payload_version) { 1 }

  describe "#expanded_links" do
    let(:edition) { create(:live_edition) }
    subject(:result) do
      described_class.new(
        edition, draft: present_drafts
      ).expanded_links
    end

    context "when there aren't links" do
      it "has a link to itself as an available translation" do
        expect(result).to match(
          available_translations: [
            a_hash_including(content_id: edition.content_id),
          ],
        )
      end
    end
  end

  describe "#for_message_queue" do
    let(:update_type) { "minor" }
    let(:edition) do
      create(
        :live_edition,
        update_type:,
        schema_name: "calendar",
        document_type: "calendar",
        auth_bypass_ids: [],
      )
    end

    subject(:result) do
      described_class.new(
        edition, draft: present_drafts
      ).for_message_queue(payload_version)
    end

    it "mixes in the specified update_type to the presentation" do
      expect(subject[:update_type]).to eq update_type
    end

    it "adds the supertypes" do
      expect(subject["user_journey_document_supertype"]).to eq "thing"
    end

    it "includes the version" do
      expect(subject[:payload_version]).to eq 1
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_notification_schema("calendar")
    end

    it "doesnt include auth_bypass_ids in message queue" do
      expect(subject).to_not include(auth_bypass_ids: [])
    end

    context "when there are links" do
      let!(:taxons_link) do
        create(
          :link,
          target_content_id: SecureRandom.uuid,
          link_set: create(:link_set, content_id: edition.content_id),
          link_type: "taxons",
        )
      end

      let!(:editions_link) do
        create(
          :link,
          target_content_id: SecureRandom.uuid,
          link_set: nil,
          edition:,
          link_type: "editions",
        )
      end

      it "presents the unexpanded links" do
        expect(subject[:links]).to match(
          taxons: [taxons_link.target_content_id],
          editions: [editions_link.target_content_id],
        )
      end
    end
  end

  describe "#for_content_store" do
    subject(:result) do
      described_class.new(
        edition, draft: present_drafts
      ).for_content_store(payload_version)
    end

    let(:base_path) { "/vat-rates" }

    let(:expected) do
      {
        content_id: edition.document.content_id,
        base_path:,
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        details:,
        document_type: "services_and_information",
        locale: "en",
        phase: "beta",
        publishing_app: "publisher",
        redirects: [],
        rendering_app: "frontend",
        routes: [{ path: base_path, type: "exact" }],
        schema_name: "generic",
        title: "VAT rates",
        first_published_at: "2014-01-02T03:04:05Z",
        public_updated_at: "2014-05-14T13:00:06Z",
      }
    end

    context "for a live edition" do
      let(:edition) do
        create(
          :live_edition,
          base_path:,
          details:,
        )
      end
      let!(:link_set) { create(:link_set, content_id: edition.document.content_id) }

      it "presents the object graph for the content store" do
        expect(result).to match(a_hash_including(expected))
      end

      it "adds the supertypes" do
        expect(result["user_journey_document_supertype"]).to be_present
      end
    end

    context "for a draft edition" do
      let(:edition) do
        create(
          :draft_edition,
          base_path:,
          details:,
          first_published_at: "2014-01-02T03:04:05Z",
          public_updated_at: "2014-05-14T13:00:06Z",
          auth_bypass_ids: [SecureRandom.uuid],
        )
      end
      let(:present_drafts) { true }

      let!(:link_set) { create(:link_set, content_id: edition.document.content_id) }

      it "presents the object graph for the content store" do
        expected.merge!(auth_bypass_ids: edition.auth_bypass_ids)
        expect(result).to match(a_hash_including(expected))
      end
    end

    context "for a withdrawn edition" do
      let!(:edition) do
        create(
          :withdrawn_unpublished_edition,
          base_path:,
          details:,
        )
      end
      let!(:link_set) { create(:link_set, content_id: edition.document.content_id) }

      it "merges in a withdrawal notice" do
        unpublishing = Unpublishing.find_by(edition:)

        expect(result).to match(
          a_hash_including(
            expected.merge(
              withdrawn_notice: {
                explanation: unpublishing.explanation,
                withdrawn_at: unpublishing.created_at.utc.iso8601,
              },
            ),
          ),
        )
      end

      context "with an overridden unpublished_at" do
        let!(:edition) do
          create(
            :withdrawn_unpublished_edition,
            base_path:,
            details:,
            unpublished_at: Time.zone.local(2016, 9, 10, 4, 5, 6),
          )
        end

        it "merges in a withdrawal notice with the withdrawn_at set correctly" do
          unpublishing = Unpublishing.find_by(edition:)

          expect(result).to match(
            a_hash_including(
              expected.merge(
                withdrawn_notice: {
                  explanation: unpublishing.explanation,
                  withdrawn_at: unpublishing.unpublished_at.iso8601,
                },
              ),
            ),
          )
        end
      end
    end

    context "for a edition with dependencies" do
      let(:main_edition)       { create(:edition, base_path: "/a") }
      let(:edition_dependee)   { create(:edition, base_path: "/c") }
      let(:document_dependent) { create(:edition, base_path: "/d") }

      before do
        link2 = create(
          :link,
          link_type: "documents",
          target_content_id: main_edition.document.content_id,
        )
        create(
          :link_set,
          content_id: document_dependent.document.content_id,
          links: [link2],
        )
        main_edition.links.create!(
          target_content_id: edition_dependee.document.content_id,
          link_type: "related",
        )
      end

      it "expands the links for the edition" do
        result = described_class.new(
          main_edition, draft: true
        ).for_content_store(payload_version)

        expect(
          result[:expanded_links][:related][0][:content_id],
        ).to eq edition_dependee.content_id

        expect(
          result[:expanded_links][:available_translations][0][:content_id],
        ).to eq main_edition.content_id

        expect(
          result[:expanded_links][:document_collections][0][:content_id],
        ).to eq document_dependent.content_id
      end
    end

    context "for a edition with change notes" do
      let(:edition) do
        create(
          :draft_edition,
          base_path:,
          details: details.slice(:body),
        )
      end
      before do
        ChangeNote.create(change_history.merge(edition:))
      end

      it "constructs the change history" do
        expect(result[:details][:change_history].first[:note]).to eq "Note"
      end
    end

    describe "conditional attributes" do
      let!(:edition) { create(:live_edition) }
      let!(:link_set) { create(:link_set, content_id: edition.document.content_id) }

      context "when the link_set is not present" do
        before { link_set.destroy }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end

      context "when the public_updated_at is not present" do
        let(:edition) { create(:gone_draft_edition) }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end
    end

    context "for an access-limited item" do
      let!(:access_limit) do
        create(:access_limit, edition:)
      end

      context "in draft" do
        let(:edition) { create(:draft_edition) }

        it "populates the access_limited hash" do
          expect(result[:access_limited][:users].length).to eq(1)
          expect(result[:access_limited][:organisations].length).to eq(1)
        end
      end

      context "in live" do
        let(:edition) { create(:live_edition) }

        it "does not send an access_limited hash" do
          expect(result).not_to include(:access_limited)
        end

        it "notifies GovukError" do
          expect(GovukError).to receive(:notify)
          result
        end
      end
    end

    describe "rendering govspeak" do
      let(:details) do
        {
          body: [
            {
              content_type: "text/govspeak",
              content: "#Hello World",
            },
          ],
        }
      end

      let(:edition) do
        create(
          :live_edition,
          base_path:,
          details:,
        )
      end

      it "renders the govspeak as html" do
        expect(result[:details][:body]).to include(
          a_hash_including(
            content_type: "text/html",
            content: "<h1 id=\"hello-world\">Hello World</h1>\n",
          ),
        )
      end

      it "returns the govspeak" do
        expect(result[:details][:body]).to include(
          content_type: "text/govspeak",
          content: "#Hello World",
        )
      end
    end
  end
end
