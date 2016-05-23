require "rails_helper"

RSpec.describe Presenters::Queries::ExpandedLinkSet do
  def create_link_set
    link_set = FactoryGirl.create(:link_set, content_id: SecureRandom.uuid)
    link_set.content_id
  end

  def create_content_item(content_id, base_path, state = "published", locale = "en")
    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      base_path: base_path,
      state: state,
      locale: locale,
    )
  end

  def create_link(from, to, link_type)
    link_set = LinkSet.find_by(content_id: from)

    FactoryGirl.create(
      :link,
      link_set: link_set,
      target_content_id: to,
      link_type: link_type,
    )
  end

  let(:a) { create_link_set }
  let(:b) { create_link_set }
  let(:c) { create_link_set }
  let(:d) { create_link_set }

  let(:locale_fallback_order) { "en" }

  subject(:expanded_links) {
    described_class.new(
      link_set: LinkSet.find_by(content_id: a),
      state_fallback_order: state_fallback_order,
      locale_fallback_order: locale_fallback_order
    ).links
  }

  context "with content items in a draft state" do
    let!(:draft_a) { create_content_item(a, "/a", "draft") }
    let!(:draft_b) { create_content_item(b, "/b", "draft") }
    let!(:draft_c) { create_content_item(c, "/c", "draft") }
    let!(:draft_d) { create_content_item(d, "/d", "draft") }

    let(:state_fallback_order) { [:draft] }

    context "a simple non-recursive graph" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(b, c, "related")

        expect(expanded_links[:related]).to match([a_hash_including(base_path: "/b", expanded_links: {})])
      end
    end

    context "a connected acylic graph" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, c, "parent")
        create_link(c, d, "parent")

        expect(expanded_links[:parent]).to match([
          a_hash_including(
            base_path: "/b",
            expanded_links: {
            parent: [a_hash_including(
              base_path: "/c",
              expanded_links: {
                parent: [
                  a_hash_including(base_path: "/d", expanded_links: {})
                ]
              })]
            })
        ])
      end
    end

    context "graph with recursive and non-recursive branches" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", expanded_links: {})
        ])
      end
    end

    context "graph with non-recursive then a recursive node" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(b, c, "parent")

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/b", expanded_links: {})
        ])
      end
    end

    context "cyclic dependencies" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(b, a, "parent")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", expanded_links: {
            parent: [a_hash_including(base_path: "/a", expanded_links: {})]
          })
        ])
      end
    end

    context "graph with multiple links" do
      it "expands the links for node a correctly" do
        create_link(a, b, "parent")
        create_link(a, c, "related")

        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b", expanded_links: {})
        ])

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/c", expanded_links: {})
        ])
      end
    end

    context "graph with multiple links of the same type" do
      it "expands the links for node a correctly" do
        create_link(a, b, "related")
        create_link(a, c, "related")

        expect(expanded_links[:related]).to match([
          a_hash_including(base_path: "/b", expanded_links: {}),
          a_hash_including(base_path: "/c", expanded_links: {}),
        ])
      end
    end

    context "when the depended on content item has no location" do
      before do
        create_link(a, b, "parent")
        Location.find_by(base_path: "/b").destroy
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
        ContentItem.find_by(content_id: b).destroy
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

        create_content_item(a, "/a", "draft")
        create_content_item(b, "/b", "draft")
        create_content_item(c, "/c", "published")
      end

      context "when requested with a draft state" do
        let(:state_fallback_order) { [:draft] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/b", expanded_links: {})
          ])
        end
      end

      context "when requested with a published state" do
        let(:state_fallback_order) { [:published] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:related]).to match([
            a_hash_including(base_path: "/c", expanded_links: {})
          ])
        end
      end
    end

    context "when one of the recursive content items does not match the provided state" do
      before do
        create_link(a, b, "parent")
        create_link(b, c, "parent")
        create_link(c, d, "parent")

        create_content_item(a, "/a-draft", "draft")
        create_content_item(b, "/b-draft", "draft")
        create_content_item(d, "/d-draft", "draft")

        create_content_item(b, "/b-published", "published")
        create_content_item(c, "/c-published", "published")
      end

      context "when requested with a draft state" do
        let(:state_fallback_order) { [:draft] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(base_path: "/b-draft", expanded_links: {})
          ])
        end
      end

      context "when requested with a published state" do
        let(:state_fallback_order) { [:published] }

        it "expands the links for node a correctly" do
          expect(expanded_links[:parent]).to match([
            a_hash_including(base_path: "/b-published", expanded_links: {
              parent: [a_hash_including(base_path: "/c-published", expanded_links: {})]
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

        create_content_item(a, "/a-draft", "draft")
        create_content_item(b, "/b-published", "published")
        create_content_item(c, "/c-draft", "draft")
        create_content_item(c, "/c-published", "published")
        create_content_item(d, "/d-published", "published")
      end

      it "expands for the content item of the first state that matches" do
        expect(expanded_links[:parent]).to match([
          a_hash_including(base_path: "/b-published", expanded_links: {
            parent: [a_hash_including(base_path: "/c-draft", expanded_links: {
              parent: [a_hash_including(base_path: "/d-published", expanded_links: {})]
            })]
          })
        ])
      end
    end
  end

  context "when a link has a 'passthrough_hash'" do
    let(:state_fallback_order) { [:draft, :published] }

    before do
      create_link(a, b, "parent")
      create_link(b, c, "parent")

      create_content_item(a, "/a", "draft")
      create_content_item(b, "/b", "draft")
      create_content_item(c, "/c", "draft")

      bc_link = Link.last
      bc_link.target_content_id = { foo: "bar" }
      bc_link.save!
    end

    it "does not expand the fields for those links" do
      expect(expanded_links[:parent]).to match([
        a_hash_including(base_path: "/b", expanded_links: {})
      ])
    end
  end

  describe "multiple translations" do
    let(:state_fallback_order) { [:published] }
    let(:locale_fallback_order) { %w(ar en) }

    before do
      create_link(a, b, "organisation")
      create_content_item(a, "/a", "published", "en")
      create_content_item(b, "/b", "published", "en")
    end

    context "when a linked item exists in multiple locales" do
      let!(:arabic_b) { create_content_item(b, "/b.ar", "published", "ar") }

      it "links to the item in the matching locale" do
        expect(expanded_links[:organisation]).to match([
          a_hash_including(base_path: "/b.ar")
        ])
      end
    end

    context "when the item exists in the matching locale but a fallback state" do
      let(:state_fallback_order) { [:draft, :published] }
      let!(:arabic_b) { create_content_item(b, "/b.ar", "published", "ar") }

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

  describe "expanding dependees" do
    let(:state_fallback_order) { [:draft, :published] }

    before do
      create_content_item(a, "/a")
      create_content_item(b, "/b")
      create_content_item(c, "/c")
      create_content_item(d, "/d")

      create_link(d, c, "parent")
      create_link(c, b, "parent")
      create_link(b, a, "parent")
    end

    it "automatically expands reverse dependencies to one level of depth" do
      expect(expanded_links[:children]).to match([
        a_hash_including(
          base_path: "/b",
          expanded_links: a_hash_including(
            parent: [a_hash_including(
              base_path: "/a",
              expanded_links: anything,
            )]
          )
        )
      ])
    end
  end
end
