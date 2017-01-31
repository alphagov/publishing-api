require 'rails_helper'

RSpec.describe Presenters::EditionPresenter do
  let(:present_drafts) { false }
  let(:change_history) { { note: "Note", public_timestamp: 1.day.ago.to_s } }
  let(:details) { { body: "<p>Text</p>\n", change_history: [change_history], } }
  let(:payload_version) { 1 }

  describe "#for_message_queue" do
    let(:update_type) { "moussaka" }
    let(:edition) { FactoryGirl.create(:draft_edition) }
    let(:target_content_id) { "d16216ce-7487-4bde-b817-ef68317fe3ab" }

    before do
      link_set = FactoryGirl.create(
        :link_set, content_id: edition.document.content_id
      )
      FactoryGirl.create(
        :link,
        target_content_id: target_content_id,
        link_set: link_set,
        link_type: "taxons"
      )
    end

    subject(:result) do
      described_class.new(
        edition, draft: present_drafts
      ).for_message_queue(update_type)
    end

    it "presents the unexpanded links" do
      expect(subject[:links]).to eq taxons: [target_content_id]
    end

    it "mixes in the specified update_type to the presentation" do
      expect(subject[:update_type]).to eq update_type
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
        base_path: base_path,
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        details: details,
        document_type: "guide",
        format: "guide",
        locale: "en",
        need_ids: %w(100123 100124),
        phase: "beta",
        publishing_app: "publisher",
        redirects: [],
        rendering_app: "frontend",
        routes: [{ path: base_path, type: "exact" }],
        schema_name: "guide",
        title: "VAT rates",
        first_published_at: DateTime.parse("2014-01-02T03:04:05Z"),
        public_updated_at: DateTime.parse("2014-05-14T13:00:06Z"),
        update_type: "minor",
      }
    end

    context "for a live edition" do
      let(:edition) do
        FactoryGirl.create(:live_edition,
          base_path: base_path,
          details: details)
      end
      let!(:link_set) { FactoryGirl.create(:link_set, content_id: edition.document.content_id) }

      it "presents the object graph for the content store" do
        expect(result).to match(a_hash_including(expected))
      end
    end

    context "for a draft edition" do
      let(:edition) do
        FactoryGirl.create(:draft_edition,
          base_path: base_path,
          details: details)
      end
      let!(:link_set) { FactoryGirl.create(:link_set, content_id: edition.document.content_id) }

      it "presents the object graph for the content store" do
        expect(result).to match(a_hash_including(expected))
      end
    end

    context "for a withdrawn edition" do
      let!(:edition) do
        FactoryGirl.create(:withdrawn_unpublished_edition,
          base_path: base_path,
          details: details)
      end
      let!(:link_set) { FactoryGirl.create(:link_set, content_id: edition.document.content_id) }

      it "merges in a withdrawal notice" do
        unpublishing = Unpublishing.find_by(edition: edition)

        expect(result).to match(
          a_hash_including(
            expected.merge(
              withdrawn_notice: {
                explanation: unpublishing.explanation,
                withdrawn_at: unpublishing.created_at.iso8601,
              }
            )
          )
        )
      end

      context "with an overridden unpublished_at" do
        let!(:edition) do
          FactoryGirl.create(:withdrawn_unpublished_edition,
            base_path: base_path,
            details: details,
            unpublished_at: DateTime.new(2016, 9, 10, 4, 5, 6)
          )
        end

        it "merges in a withdrawal notice with the withdrawn_at set correctly" do
          unpublishing = Unpublishing.find_by(edition: edition)

          expect(result).to match(
            a_hash_including(
              expected.merge(
                withdrawn_notice: {
                  explanation: unpublishing.explanation,
                  withdrawn_at: unpublishing.unpublished_at.iso8601,
                }
              )
            )
          )
        end
      end
    end

    context "for a edition with dependencies" do
      let(:main_edition)       { FactoryGirl.create(:edition, base_path: "/a") }
      let(:document_dependee)  { FactoryGirl.create(:edition, base_path: "/b") }
      let(:edition_dependee)   { FactoryGirl.create(:edition, base_path: "/c") }
      let(:document_dependent) { FactoryGirl.create(:edition, base_path: "/d") }
      let(:edition_dependent)  { FactoryGirl.create(:edition, base_path: "/e") }

      before do
        link = FactoryGirl.create(
          :link,
          link_type: "related",
          target_content_id: document_dependee.document.content_id,
        )
        FactoryGirl.create(
          :link_set,
          content_id: main_edition.document.content_id,
          links: [ link ],
        )
        link2 = FactoryGirl.create(
          :link,
          link_type: "documents",
          target_content_id: main_edition.document.content_id,
        )
        FactoryGirl.create(
          :link_set,
          content_id: document_dependent.document.content_id,
          links: [ link2 ],
        )
        main_edition.links.create!(
          target_content_id: edition_dependee.document.content_id,
          link_type: "related",
        )
        edition_dependent.links.create!(
          target_content_id: main_edition.document.content_id,
          link_type: "documents",
        )
      end

      subject do
        described_class.new(a, draft: true).for_content_store(payload_version)
      end

      it "expands the links for the edition" do
        expect(subject[:expanded_links]).to eq(
          related: [{
            content_id: b.document.content_id,
            api_path: "/api/content/b",
            base_path: "/b",
            title: "VAT rates",
            description: "VAT rates for goods and services",
            schema_name: "guide",
            document_type: 'guide',
            locale: "en",
            public_updated_at: "2014-05-14T13:00:06Z",
            analytics_identifier: "GDS01",
            links: {},
            withdrawn: false,
          }],
          available_translations: [{
            analytics_identifier: "GDS01",
            api_path: "/api/content/a",
            base_path: "/a",
            content_id: a.document.content_id,
            description: "VAT rates for goods and services",
            schema_name: "guide",
            document_type: 'guide',
            locale: "en",
            public_updated_at: "2014-05-14T13:00:06Z",
            title: "VAT rates",
            withdrawn: false,
          }],
        )
      end

      it "expands the links for the edition" do
        result = described_class.present(
          main_edition, draft: true
        )

        expect(
          result[:expanded_links][:related].map { |link| link[:content_id] }
        ).to eq [ document_dependee.content_id, edition_dependee.content_id ]

        expect(
          result[:expanded_links][:available_translations][0][:content_id]
        ).to eq main_edition.content_id

        expect(
          result[:expanded_links][:document_collections].map{ |link| link[:content_id] }
        ).to eq [ document_dependent.content_id, edition_dependent.content_id ]
      end
    end

    context "for a edition with change notes" do
      let(:edition) do
        FactoryGirl.create(:draft_edition,
          base_path: base_path,
          details: details.slice(:body))
      end
      before do
        ChangeNote.create(change_history.merge(edition: edition, content_id: edition.document.content_id))
      end

      it "constructs the change history" do
        expect(result[:details][:change_history].first[:note]).to eq "Note"
      end
    end

    describe "conditional attributes" do
      let!(:edition) { FactoryGirl.create(:live_edition) }
      let!(:link_set) { FactoryGirl.create(:link_set, content_id: edition.document.content_id) }

      context "when the link_set is not present" do
        before { link_set.destroy }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end

      context "when the public_updated_at is not present" do
        let(:edition) { FactoryGirl.create(:gone_draft_edition) }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end
    end

    context "for an access-limited item" do
      let!(:access_limit) {
        FactoryGirl.create(:access_limit, edition: edition)
      }

      context "in draft" do
        let(:edition) { FactoryGirl.create(:draft_edition) }

        it "populates the access_limited hash" do
          expect(result[:access_limited][:users].length).to eq(1)
          expect(result[:access_limited][:fact_check_ids].length).to eq(0)
        end
      end

      context "in live" do
        let(:edition) { FactoryGirl.create(:live_edition) }

        it "does not send an access_limited hash" do
          expect(result).not_to include(:access_limited)
        end

        it "notifies Airbrake" do
          expect(Airbrake).to receive(:notify)
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
              content: "#Hello World"
            },
          ],
        }
      end

      let(:edition) do
        FactoryGirl.create(:live_edition,
          base_path: base_path,
          details: details,
        )
      end

      it "renders the govspeak as html" do
        expect(result[:details][:body]).to include(
          a_hash_including(
            content_type: "text/html",
            content: "<h1 id=\"hello-world\">Hello World</h1>\n",
          )
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
