RSpec.describe Presenters::Queries::ExpandedLinkSet do
  include DependencyResolutionHelper

  let(:a) { create_link_set }
  let(:b) { create_link_set }

  let(:locale) { "en" }
  let(:with_drafts) { false }

  subject(:expanded_links) do
    described_class.by_content_id(
      a,
      locale:,
      with_drafts:,
    ).links
  end

  describe "multiple translations" do
    let(:locale_fallback_order) { %w[ar en] }

    before do
      create_link(a, b, "organisation")
      create_edition(a, "/a", locale: "en")
      create_edition(b, "/b", locale: "en")
    end

    context "when a linked item exists in multiple locales" do
      let!(:arabic_a) { create_edition(a, "/a.fr", locale: "fr") }

      it "links to the available translations" do
        expect(expanded_links[:available_translations]).to match_array([
          a_hash_including(base_path: "/a"),
          a_hash_including(base_path: "/a.fr"),
        ])
      end
    end
  end

  describe "details" do
    let(:c) { create_link_set }

    context "without embedded content in the body" do
      before do
        create_edition(a, "/a", document_type: "person")
        create_edition(
          b,
          "/b",
          document_type: "ministerial_role",
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "Body",
              },
            ],
          },
        )
        create_edition(c, "/c", document_type: "role_appointment")

        create_link(c, a, "person")
        create_link(c, b, "role")
      end

      it "recursively calls the details presenter and renders govspeak inside expanded links" do
        b = expanded_links[:role_appointments].first
        c = b[:links][:role].first
        expect(c[:details][:body]).to match([
          {
            content_type: "text/govspeak",
            content: "Body",
          },
          {
            content_type: "text/html",
            content: "<p>Body</p>\n",
          },
        ])
      end
    end

    context "with embedded content in the body" do
      let(:contact) do
        create(:edition, state: "published", content_store: "live", document_type: "contact", title: "Some contact")
      end

      before do
        create_edition(a, "/a", document_type: "person")
        create_edition(
          b,
          "/b",
          document_type: "ministerial_role",
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "{{embed:contact:#{contact.document.content_id}}}",
              },
            ],
          },
          links_hash: { embed: [contact.document.content_id] },
        )
        create_edition(c, "/c", document_type: "role_appointment")

        create_link(c, a, "person")
        create_link(c, b, "role")
      end

      it "recursively calls the details presenter and embeds content inside expanded links" do
        b = expanded_links[:role_appointments].first
        c = b[:links][:role].first
        expect(c[:details][:body]).to match([
          {
            content_type: "text/govspeak",
            content: "Some contact",
          },
          {
            content_type: "text/html",
            content: "<p>Some contact</p>\n",
          },
        ])
      end
    end
  end
end
