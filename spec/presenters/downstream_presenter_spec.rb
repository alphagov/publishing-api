require 'rails_helper'

RSpec.describe Presenters::DownstreamPresenter do
  def web_content_item_for(edition)
    Queries::GetWebContentItems.(edition.id).first
  end

  let(:present_drafts) { false }
  let(:web_content_item) { web_content_item_for(edition) }
  let(:change_history) { { note: "Note", public_timestamp: 1.day.ago.to_s } }
  let(:details) { { body: "<p>Text</p>\n", change_history: [change_history], } }

  subject(:result) { described_class.present(web_content_item, draft: present_drafts) }

  describe "V2" do
    let(:base_path) { "/vat-rates" }

    let(:expected) {
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
        first_published_at: "2014-01-02T03:04:05Z",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "publisher",
        redirects: [],
        rendering_app: "frontend",
        routes: [{ path: base_path, type: "exact" }],
        schema_name: "guide",
        title: "VAT rates",
        update_type: "minor"
      }
    }

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
      let(:a) { FactoryGirl.create(:edition, base_path: "/a") }
      let(:b) { FactoryGirl.create(:edition, base_path: "/b") }

      before do
        FactoryGirl.create(:link_set, content_id: a.document.content_id, links: [
          FactoryGirl.create(:link, link_type: "related", target_content_id: b.document.content_id)
        ])
      end

      it "expands the links for the edition" do
        result = described_class.present(web_content_item_for(a), draft: true)

        expect(result[:expanded_links]).to eq(
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
