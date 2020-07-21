require "rails_helper"

RSpec.describe "Link Expansion" do
  include DependencyResolutionHelper

  let(:a) { create_link_set }
  let(:b) { create_link_set }
  let(:c) { create_link_set }
  let(:d) { create_link_set }
  let(:e) { create_link_set }
  let(:f) { create_link_set }
  let(:g) { create_link_set }

  subject(:expanded_links) do
    LinkExpansion.by_content_id(
      content_id,
      locale: locale,
      with_drafts: with_drafts,
    ).links_with_content
  end

  subject(:expanded_links_by_edition) do
    LinkExpansion.by_edition(
      edition,
      with_drafts: with_drafts,
    ).links_with_content
  end

  let(:content_id) { a }
  let(:locale) { "en" }

  describe "content without links" do
    let(:with_drafts) { true }
    it "performs no expansion" do
      expect(expanded_links).to be_empty
    end
  end

  describe "non-renderable editions" do
    let!(:draft_a) { create_edition(a, "/a", factory: :draft_edition) }
    let!(:redirect) { create_edition(b, "/b", factory: :redirect_draft_edition) }
    let!(:gone) { create_edition(c, "/c", factory: :gone_edition) }

    let(:with_drafts) { true }

    context "a simple non-recursive graph" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(a, c, "related")

        expect(expanded_links[:related]).not_to be
      end
    end
  end

  describe "editions in a draft state" do
    let!(:draft_a) { create_edition(a, "/a", factory: :draft_edition) }
    let!(:draft_b) { create_edition(b, "/b", factory: :draft_edition) }
    let!(:draft_c) { create_edition(c, "/c", factory: :draft_edition) }
    let!(:draft_d) { create_edition(d, "/d", factory: :draft_edition) }
    let!(:draft_e) { create_edition(e, "/e", factory: :draft_edition) }
    let!(:draft_f) { create_edition(f, "/f", factory: :draft_edition) }
    let!(:draft_g) { create_edition(g, "/g", factory: :draft_edition) }

    let(:with_drafts) { true }

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
                    a_hash_including(base_path: "/d", links: {}),
                  ],
                },
              )],
            },
          ),
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
            links: {},
          ),
        ])

        expect(expanded_links[:ordered_related_items]).to match([
          a_hash_including(
            base_path: "/b",
            links: {
              mainstream_browse_pages: [a_hash_including(
                base_path: "/c",
                links: {
                  parent: [
                    a_hash_including(base_path: "/e", links: {}),
                  ],
                },
              )],
            },
          ),
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
          a_hash_including(base_path: "/d", links: {}),
        ])

        expect(expanded_links[:parent_taxons][1][:base_path]).to eq("/c")
        expect(expanded_links[:parent_taxons][1][:links][:parent_taxons]).to match([
          a_hash_including(base_path: "/d", links: {}),
        ])
      end
    end

    context "graph with recursive and non-recursive branches" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", links: {}),
        ])
      end
    end

    context "graph with non-recursive then a recursive node" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(b, c, "parent")

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/b", links: {}),
        ])
      end
    end

    context "graph with reverse links linking to direct links" do
      it "has the direct link (associated_taxons) from the reverse link (child_taxons)" do
        create_link(b, a, "parent_taxons")
        create_link(b, c, "associated_taxons")

        expect(expanded_links[:child_taxons]).to match([
          a_hash_including(
            base_path: "/b",
            links: a_hash_including(:associated_taxons),
          ),
        ])
      end
    end

    context "cyclic dependencies" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, a, "parent")

        expect(expanded_links[:parent]).to match([
          a_hash_including(
            base_path: "/b",
            links: {
              parent: [a_hash_including(base_path: "/a", links: {})],
            },
          ),
        ])
      end
    end

    context "graph with multiple links" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(a, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", links: {}),
        ])

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/c", links: {}),
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

    context "when the depended on edition has no location" do
      before do
        create_link(a, b, "parent")
        Edition.find_by(base_path: "/b").update!(base_path: nil)
      end

      it "has no web_url" do
        expect(expanded_links[:parent].first[:web_url]).to_not be
      end

      it "still has a locale" do
        expect(expanded_links[:parent].first[:locale]).to eq("en")
      end
    end

    context "when the depended on edition does not exist" do
      before do
        create_link(a, b, "parent")
        Edition.with_document.find_by('documents.content_id': b).destroy!
      end

      it "does not have a parent" do
        expect(expanded_links[:parent]).to be_nil
      end
    end
  end

  describe "editions in different states" do
    context "when a edition is in a state that does not match the provided state" do
      before do
        create_link(a, b, "related")
        create_link(a, c, "related")

        create_edition(a, "/a", factory: :draft_edition)
        create_edition(b, "/b", factory: :draft_edition)
        create_edition(c, "/c")
      end

      context "when requested with a draft state" do
        let(:with_drafts) { true }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/b", links: {}),
            a_hash_including(base_path: "/c", links: {}),
          ])
        end
      end

      context "when requested with a published state" do
        let(:with_drafts) { false }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/c", links: {}),
          ])
        end
      end
    end

    context "when a published edition is linked to content in draft" do
      before do
        create_link(a, b, "related")
        create_edition(a, "/a-published")
        create_edition(b, "/b-draft", factory: :draft_edition)
      end

      context "without drafts" do
        let(:with_drafts) { false }

        it "does not expose the draft item in expanded links" do
          expect(expanded_links[:related]).not_to match(a_hash_including(base_path: "/b-draft"))
        end
      end

      context "with drafts" do
        let(:with_drafts) { true }

        it "exposes the draft item in expanded links" do
          expect(expanded_links[:related]).to match([a_hash_including(base_path: "/b-draft")])
        end
      end
    end

    context "when one of the recursive editions does not match the provided state" do
      before do
        create_link(a, b, "parent")
        create_link(b, c, "parent")

        create_edition(a, "/a-published")
        create_edition(b, "/b-published")
        create_edition(c, "/c-draft", factory: :draft_edition, version: 2)
      end

      context "when requested with drafts" do
        let(:with_drafts) { true }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(
              base_path: "/b-published",
              links: {
                parent: [a_hash_including(base_path: "/c-draft", links: {})],
              },
            ),
          ])
        end
      end

      context "when requested without drafts" do
        let(:with_drafts) { false }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(base_path: "/b-published", links: {}),
          ])
        end
      end
    end
  end

  describe "multiple translations" do
    let(:with_drafts) { false }
    let(:locale) { "ar" }

    before do
      create_link(a, b, "organisation")
      create_edition(a, "/a", locale: "en")
      create_edition(b, "/b", locale: "en")
    end

    context "when a linked item exists in multiple locales" do
      let!(:arabic_b) { create_edition(b, "/b.ar", locale: "ar") }

      it "links to the item in the matching locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b.ar"),
        ])
      end
    end

    context "when the item exists in the matching locale but not in a draft state" do
      let(:with_drafts) { true }
      let!(:arabic_b) { create_edition(b, "/b.ar", locale: "ar") }

      it "links to the item in the matching locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b.ar"),
        ])
      end
    end

    context "when the item exists in the matching state but a fallback locale" do
      it "links to the item in the fallback locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b"),
        ])
      end
    end

    context "when the item exists in a matching state and locale" do
      let(:with_drafts) { true }
      it "links to the item in the fallback locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b"),
        ])
      end
    end
  end

  describe "expanding withdrawn dependents" do
    let(:with_drafts) { false }

    before do
      create_edition(a, "/a", factory: :withdrawn_unpublished_edition)
      create_edition(b, "/b", factory: :withdrawn_unpublished_edition)
      create_edition(c, "/c")
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
      expect(parents_base_paths).to eq(["/a", "/a"])
    end
  end

  describe "expanding dependents" do
    let(:with_drafts) { true }

    context "parents" do
      before do
        create_edition(a, "/a-draft", factory: :draft_edition)
        create_edition(b, "/b-published")
        create_edition(c, "/c-published")
        create_edition(d, "/d-published")

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
              )],
            ),
          ),
        ])
      end

      context "without drafts" do
        let(:with_drafts) { false }

        it "excludes draft dependees" do
          expect(expanded_links[:children]).to match([
            a_hash_including(base_path: "/b-published", links: {}),
          ])
        end
      end
    end

    context "parent_taxons" do
      before do
        create_edition(a, "/a")
        create_edition(b, "/b")
        create_edition(c, "/c")
        create_edition(d, "/d")
        create_edition(e, "/e")

        create_link(e, d, "parent_taxons")
        create_link(d, c, "parent_taxons")
        create_link(c, b, "parent_taxons")
        create_link(b, a, "parent_taxons")
      end

      let(:child_taxons) do
        [a_hash_including(
          base_path: "/b",
          links: a_hash_including(
            child_taxons: [a_hash_including(
              base_path: "/c",
              links: a_hash_including(
                child_taxons: [a_hash_including(
                  base_path: "/d",
                  links: a_hash_including(
                    child_taxons: [a_hash_including(
                      base_path: "/e",
                    )],
                  ),
                )],
              ),
            )],
          ),
        )]
      end

      it "includes each depth of the parent_taxons as child_taxons" do
        expect(expanded_links[:child_taxons]).to match(child_taxons)
      end
    end
  end

  describe "withdrawn edition as a parent" do
    let(:with_drafts) { false }

    before do
      create_edition(a, "/a")
      create_edition(b, "/b", factory: :withdrawn_unpublished_edition)
      create_edition(c, "/c", factory: :withdrawn_unpublished_edition)
    end

    context "a simple non-recursive graph" do
      before do
        create_link(a, b, "parent")
        create_link(a, c, "related")
      end

      it "expands the links for node a correctly" do
        expect(expanded_links[:parent]).to match([a_hash_including('base_path': "/b")])
        expect(expanded_links[:related]).to match(nil)
      end
    end
  end

  describe "edition-level links across multiple locales" do
    let(:with_drafts) { false }
    let(:content_id) { a }
    let(:en_document) { create(:document, content_id: content_id) }
    let(:fr_document) do
      create(:document, content_id: content_id, locale: "fr")
    end
    let!(:en_edition) { create(:live_edition, document: en_document) }
    let!(:fr_edition) { create(:live_edition, document: fr_document) }

    let(:target_edition) do
      create(:live_edition, base_path: "/t")
    end

    before do
      fr_edition.links.create(
        link_type: "test",
        target_content_id: target_edition.content_id,
      )
    end

    context "only english links" do
      let(:locale) { "en" }

      it "should not expand a link to" do
        expect(expanded_links).to be_empty
      end
    end

    context "english and french links" do
      let(:locale) { "fr" }

      it "should not expand a link to" do
        expect(expanded_links).to_not be_empty
        expect(expanded_links[:test]).to match([a_hash_including(base_path: "/t")])
      end
    end
  end

  describe "local edition data out of sync with database" do
    let(:with_drafts) { false }

    let!(:parent_edition) { create_edition(a, "/a") }
    let!(:child_edition) { create_edition(b, "/b") }

    before do
      create_link(b, a, "parent", 0)
      Edition.where(id: parent_edition.id).update_all(title: "A title")
    end

    context "when passed an edition" do
      let(:edition) { parent_edition }

      it "returns the data within the edition rather than the database" do
        expect(expanded_links_by_edition[:children]).to match([
          a_hash_including(base_path: "/b", links: { parent: [a_hash_including(base_path: "/a", title: "VAT rates")] }),
        ])
      end
    end

    context "when passed a content_id and locale" do
      let(:content_id) { parent_edition.content_id }
      let(:locale) { parent_edition.locale }

      it "returns the data as is stored in the database" do
        expect(expanded_links[:children]).to match([
          a_hash_including(base_path: "/b", links: { parent: [a_hash_including(base_path: "/a", title: "A title")] }),
        ])
      end
    end
  end

  describe "draft only fields" do
    let(:auth_bypass_ids) { [SecureRandom.uuid] }

    before do
      create_link(b, a, "pages_part_of_step_nav")
      create(
        :live_edition,
        document: Document.find_or_create_by(content_id: b, locale: "en"),
        base_path: "/step-by-step",
        schema_name: "step_by_step_nav",
        document_type: "step_by_step_nav",
        auth_bypass_ids: auth_bypass_ids,
      )
    end

    context "when requested with drafts" do
      let(:with_drafts) { true }

      it "includes the draft only fields" do
        expect(expanded_links[:part_of_step_navs]).to match([
          a_hash_including(base_path: "/step-by-step", auth_bypass_ids: auth_bypass_ids),
        ])
      end
    end

    context "when requested without drafts" do
      let(:with_drafts) { false }

      it "excludes the draft only fields" do
        expect(expanded_links[:part_of_step_navs]).to match([
          hash_including(base_path: "/step-by-step"),
        ])

        expect(expanded_links[:part_of_step_navs]).to match([
          hash_not_including(auth_bypass_ids: auth_bypass_ids),
        ])
      end
    end
  end
end
