require "rails_helper"

RSpec.describe Presenters::Queries::ExpandedLinkSet do
  include DependencyResolutionHelper

  let(:a) { create_link_set }
  let(:b) { create_link_set }

  let(:locale_fallback_order) { "en" }

  subject(:expanded_links) {
    described_class.new(
      content_id: a,
      draft: present_drafts,
      locale_fallback_order: locale_fallback_order
    ).links
  }

  describe "multiple translations" do
    let(:present_drafts) { false }
    let(:locale_fallback_order) { %w(ar en) }

    before do
      create_link(a, b, "organisation")
      create_edition(a, "/a", locale: "en")
      create_edition(b, "/b", locale: "en")
    end

    context "when a linked item exists in multiple locales" do
      let!(:arabic_a) { create_edition(a, "/a.fr", locale: "fr") }

      it "links to the available translations" do
        expect(expanded_links[:available_translations]).to match([
          a_hash_including(base_path: "/a"),
          a_hash_including(base_path: "/a.fr")
        ])
      end
    end
  end
end
