require "rails_helper"

RSpec.describe Presenters::Queries::ExpandedLinkSet do
  include DependencyResolutionHelper

  let(:a) { create_link_set }
  let(:b) { create_link_set }
  let(:c) { create_link_set }
  let(:d) { create_link_set }
  let(:e) { create_link_set }
  let(:f) { create_link_set }
  let(:g) { create_link_set }

  let(:locale_fallback_order) { "en" }

  subject(:expanded_links) {
    described_class.new(
      content_id: a,
      state_fallback_order: state_fallback_order,
      locale_fallback_order: locale_fallback_order
    ).links
  }

  context "with content items that are non-renderable" do
    let!(:draft_a) { create_content_item(a, "/a", factory: :draft_content_item) }
    let!(:redirect) { create_content_item(b, "/b", factory: :redirect_draft_content_item) }
    let!(:gone) { create_content_item(c, "/c", factory: :gone_content_item) }

    let(:state_fallback_order) { [:draft] }

    context "a simple non-recursive graph" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(a, c, "related")

        expect(expanded_links[:related]).to match(nil)
      end
    end
  end

  context "with content items in a draft state" do
    let!(:draft_a) { create_content_item(a, "/a", factory: :draft_content_item) }
    let!(:draft_b) { create_content_item(b, "/b", factory: :draft_content_item) }
    let!(:draft_c) { create_content_item(c, "/c", factory: :draft_content_item) }
    let!(:draft_d) { create_content_item(d, "/d", factory: :draft_content_item) }
    let!(:draft_e) { create_content_item(e, "/e", factory: :draft_content_item) }
    let!(:draft_f) { create_content_item(f, "/f", factory: :draft_content_item) }
    let!(:draft_g) { create_content_item(g, "/g", factory: :draft_content_item) }

    let(:state_fallback_order) { [:draft] }

    context "a simple non-recursive graph" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(b, c, "related")

        expect(expanded_links[:related]).to match([a_hash_including(base_path: "/b", links: {})])
      end
    end

    context "a connected acyclic graph" do
      it "expands the links for node a correctly" do
        create_link(a, e, "document")
        create_link(a, b, "parent")
        create_link(b, c, "parent")
        create_link(c, d, "parent")

        expect(expanded_links[:parent]).to match([
          a_hash_including(
            base_path: "/b",
            links: {
              parent: [a_hash_including(
                base_path: "/c",
                links: {
                  parent: [
                    a_hash_including(base_path: "/d", links: {})
                  ]
                })]
            })
        ])
      end
    end

    context "ordered related items" do
      it "expands the links for node a correctly" do
        create_link(b, d, "ordered_related_items")
        create_link(a, b, "ordered_related_items")
        create_link(b, c, "mainstream_browse_pages")
        create_link(c, e, "parent")
        create_link(a, f, "mainstream_browse_pages")
        create_link(f, g, "parent")

        expect(expanded_links[:mainstream_browse_pages]).to match([
          a_hash_including(
            base_path: "/f",
            links: {}
          )
        ])

        expect(expanded_links[:ordered_related_items]).to match([
          a_hash_including(
            base_path: "/b",
            links: {
              mainstream_browse_pages: [a_hash_including(
                base_path: "/c",
                links: {
                  parent: [
                    a_hash_including(base_path: "/e", links: {})
                  ]
                })]
            }
          )
        ])
      end
    end

    context "multiple parent taxons" do
      it "expands all the parents" do
        create_link(a, b, "parent_taxons")
        create_link(a, c, "parent_taxons")
        create_link(b, d, "parent_taxons")
        create_link(c, d, "parent_taxons")

        expect(expanded_links[:parent_taxons][0][:base_path]).to eq("/b")
        expect(expanded_links[:parent_taxons][0][:links][:parent_taxons]).to match([
          a_hash_including(base_path: "/d", links: {})
        ])

        expect(expanded_links[:parent_taxons][1][:base_path]).to eq("/c")
        expect(expanded_links[:parent_taxons][1][:links][:parent_taxons]).to match([
          a_hash_including(base_path: "/d", links: {})
        ])
      end
    end

    context "graph with recursive and non-recursive branches" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", links: {})
        ])
      end
    end

    context "graph with non-recursive then a recursive node" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(b, c, "parent")

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/b", links: {})
        ])
      end
    end

    context "cyclic dependencies" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, a, "parent")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", links: {
            parent: [a_hash_including(base_path: "/a", links: {})]
          })
        ])
      end
    end

    context "graph with multiple links" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(a, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", links: {})
        ])

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/c", links: {})
        ])
      end
    end

    context "graph with multiple links of the same type" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related", 0)
        create_link(a, c, "related", 1)

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/b", links: {}),
          a_hash_including(base_path: "/c", links: {}),
        ])
      end
    end

    context "when the depended on content item has no location" do
      before do
        create_link(a, b, "parent")
        Edition.find_by(base_path: '/b').update_attributes!(base_path: nil)
      end

      it "has no web_url" do
        expect(expanded_links[:parent].first[:web_url]).to_not be
      end

      it "still has a locale" do
        expect(expanded_links[:parent].first[:locale]).to eq("en")
      end
    end

    context "when the depended on content item does not exist" do
      before do
        create_link(a, b, "parent")
        Edition.joins(:document).find_by('documents.content_id': b).destroy
      end

      it "does not have a parent" do
        expect(expanded_links[:parent]).to be_nil
      end
    end
  end

  context "with content items in different states" do
    context "when a content item is in a state that does not match the provided state" do
      before do
        create_link(a, b, "related")
        create_link(a, c, "related")

        create_content_item(a, "/a", factory: :draft_content_item)
        create_content_item(b, "/b", factory: :draft_content_item)
        create_content_item(c, "/c")
      end

      context "when requested with a draft state" do
        let(:state_fallback_order) { [:draft] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/b", links: {})
          ])
        end
      end

      context "when requested with a published state" do
        let(:state_fallback_order) { [:published] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/c", links: {})
          ])
        end
      end
    end

    context "when a published content item is linked to content in draft" do
      before do
        create_link(a, b, "related")
        create_content_item(a, "/a-published")
        create_content_item(b, "/b-draft", factory: :draft_content_item)
      end

      context "with a fallback to published" do
        let(:state_fallback_order) { [:published] }

        it "does not expose the draft item in expanded links" do
          expect(expanded_links[:related]).not_to match(a_hash_including(base_path: "/b-draft"))
        end
      end

      context "with a fallback to draft" do
        let(:state_fallback_order) { [:draft, :published] }

        it "exposes the draft item in expanded links" do
          expect(expanded_links[:related]).to match([a_hash_including(base_path: "/b-draft")])
        end
      end
    end

    context "when one of the recursive content items does not match the provided state" do
      before do
        create_link(a, b, "parent")
        create_link(b, c, "parent")
        create_link(c, d, "parent")

        create_content_item(a, "/a-draft", factory: :draft_content_item)
        create_content_item(b, "/b-draft", factory: :draft_content_item, version: 2)
        create_content_item(d, "/d-draft", factory: :draft_content_item)

        create_content_item(b, "/b-published")
        create_content_item(c, "/c-published")
      end

      context "when requested with a draft state" do
        let(:state_fallback_order) { [:draft] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(base_path: "/b-draft", links: {})
          ])
        end
      end

      context "when requested with a published state" do
        let(:state_fallback_order) { [:published] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(base_path: "/b-published", links: {
              parent: [a_hash_including(base_path: "/c-published", links: {})]
            })
          ])
        end
      end
    end

    # We need to support an array of states to cater for the DiscardDraft
    # command which deletes the draft content item and sends the published item
    # to the draft content store. This means that we need to try to find a
    # draft, but fall back to the published item (if it exists).
    context "when an array of states is provided" do
      let(:state_fallback_order) { [:draft, :published] }

      before do
        create_link(a, b, "parent")
        create_link(b, c, "parent")
        create_link(c, d, "parent")

        create_content_item(a, "/a-draft", factory: :draft_content_item)
        create_content_item(b, "/b-published")
        create_content_item(c, "/c-draft", factory: :draft_content_item, version: 2)
        create_content_item(c, "/c-published")
        create_content_item(d, "/d-published")
      end

      it "expands for the content item of the first state that matches" do
        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b-published", links: {
            parent: [a_hash_including(base_path: "/c-draft", links: {
              parent: [a_hash_including(base_path: "/d-published", links: {})]
            })]
          })
        ])
      end
    end
  end

  describe "multiple translations" do
    let(:state_fallback_order) { [:published] }
    let(:locale_fallback_order) { %w(ar en) }

    before do
      create_link(a, b, "organisation")
      create_content_item(a, "/a", locale: "en")
      create_content_item(b, "/b", locale: "en")
    end

    context "when a linked item exists in multiple locales" do
      let!(:arabic_b) { create_content_item(b, "/b.ar", locale: "ar") }

      it "links to the item in the matching locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b.ar")
        ])
      end
    end

    context "when the item exists in the matching locale but a fallback state" do
      let(:state_fallback_order) { [:draft, :published] }
      let!(:arabic_b) { create_content_item(b, "/b.ar", locale: "ar") }

      it "links to the item in the matching locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b.ar")
        ])
      end
    end

    context "when the item exists in the matching state but a fallback locale" do
      it "links to the item in the fallback locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b")
        ])
      end
    end

    context "when the item exists in a fallback state and locale" do
      let(:state_fallback_order) { [:draft, :published] }
      it "links to the item in the fallback locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b")
        ])
      end
    end
  end

  describe "expanding withdrawn dependents" do
    let(:state_fallback_order) { [:published] }

    before do
      create_content_item(a, "/a", factory: :withdrawn_unpublished_content_item)
      create_content_item(b, "/b", factory: :withdrawn_unpublished_content_item)
      create_content_item(c, "/c")
      create_link(b, a, "parent")
      create_link(c, a, "parent")
    end

    it "does include withdrawn dependents" do
      base_paths = expanded_links[:children].map { |c| c[:base_path] }
      expect(base_paths).to include("/b")
      expect(base_paths).to include("/c")
    end

    it "includes withdrawn parent of the dependent" do
      parents_base_paths = expanded_links[:children].map { |c| c[:links][:parent] }.flatten.map { |e| e[:base_path] }
      expect(parents_base_paths).to eq(['/a', '/a'])
    end
  end

  describe "expanding dependents" do
    let(:state_fallback_order) { [:draft, :published] }

    before do
      create_content_item(a, "/a-draft", factory: :draft_content_item)
      create_content_item(b, "/b-published")
      create_content_item(c, "/c-published")
      create_content_item(d, "/d-published")

      create_link(d, c, "parent")
      create_link(c, b, "parent")
      create_link(b, a, "parent")
    end

    it "automatically expands reverse dependencies to one level of depth" do
      expect(expanded_links[:children]).to match([
        a_hash_including(
          base_path: "/b-published",
          links: a_hash_including(
            parent: [a_hash_including(
              base_path: "/a-draft",
              links: anything,
            )]
          )
        )
      ])
    end

    context "with a state fallback to published" do
      let(:state_fallback_order) { [:published] }

      it "excludes draft dependees" do
        expect(expanded_links[:children]).to match([
          a_hash_including(base_path: "/b-published", links: {})
        ])
      end
    end
  end

  context "with a withdrawn content item as a parent" do
    let(:state_fallback_order) { [:published, :withdrawn] }

    before do
      create_content_item(a, "/a")
      create_content_item(b, "/b", factory: :withdrawn_unpublished_content_item)
      create_content_item(c, "/c", factory: :withdrawn_unpublished_content_item)
    end

    context "a simple non-recursive graph" do
      before do
        create_link(a, b, "parent")
        create_link(a, c, "related")
      end

      it "expands the links for node a correctly" do
        expect(expanded_links[:parent]).to match([a_hash_including('base_path': '/b')])
        expect(expanded_links[:related]).to match(nil)
      end
    end
  end
end
