require "rails_helper"

RSpec.describe "Dependency Resolution" do
  include DependencyResolutionHelper

  subject(:dependency_resolution) do
    DependencyResolution.new(content_id,
      locale: locale,
      with_drafts: with_drafts,
    ).dependencies
  end

  let(:content_id) { SecureRandom.uuid }
  let(:locale) { :en }
  let(:with_drafts) { true }

  context "when there are no links" do
    it "finds no dependencies" do
      expect(dependency_resolution).to be_empty
    end
  end

  context "when there are links from this content_id to another one, but not a link back" do
    before { create_link_set(content_id, links_hash: { organisation: [SecureRandom.uuid] }) }

    it "finds no dependencies" do
      expect(dependency_resolution).to be_empty
    end
  end

  context "when there are links to the contend_id" do
    let(:links_to_content_id) { SecureRandom.uuid }
    let(:linked_to) { [links_to_content_id] }
    before { create_link_set(links_to_content_id, links_hash: { organistion: [content_id] }) }

    it "has a dependency" do
      expect(dependency_resolution).to match_array([links_to_content_id])
    end
  end

  context "when an item links to an item that links to the content_id" do
    let(:a) { SecureRandom.uuid }
    let(:b) { SecureRandom.uuid }
    let(:link_type) { :organisation }

    before do
      create_link_set(a, links_hash: { link_type => [content_id] })
      create_link_set(b, links_hash: { link_type => [a] })
    end

    it "has a dependency only to the direct link" do
      expect(dependency_resolution).to match_array([a])
    end

    context "and the link_type is recursive" do
      let(:link_type) { :parent_taxons }

      it "has a dependency to both items" do
        expect(dependency_resolution).to match_array([a, b])
      end
    end
  end

  context "when there is a cyclic link structure" do
    let(:a) { SecureRandom.uuid }
    let(:b) { SecureRandom.uuid }

    # a links to b, b links to a
    before do
      create_link_set(a, links_hash: { parent_taxons: [content_id, b] })
      create_link_set(b, links_hash: { parent_taxons: [a] })
    end

    it "has a dependency to both items, and doesn't recurse forever" do
      expect(dependency_resolution).to match_array([a, b])
    end
  end

  context "when there are ordered_related_items, mainstream_browse_pages, parent" do
    let(:a) { SecureRandom.uuid }
    let(:b) { SecureRandom.uuid }
    let(:c) { SecureRandom.uuid }

    context "and the links are a valid path" do
      before do
        create_link_set(a, links_hash: { ordered_related_items: [b] })
        create_link_set(b, links_hash: { mainstream_browse_pages: [c] })
        create_link_set(c, links_hash: { parent: [content_id] })
      end

      it "has a dependency to all items" do
        expect(dependency_resolution).to match_array([a, b, c])
      end
    end

    context "but the links are an invalid path" do
      before do
        create_link_set(a, links_hash: { mainstream_browse_pages: [b] })
        create_link_set(b, links_hash: { ordered_related_items: [c] })
        create_link_set(c, links_hash: { parent: [content_id] })
      end

      it "has a dependency to just parent" do
        expect(dependency_resolution).to match_array([c])
      end
    end

    context "and there are additional parents links" do
      let(:d) { SecureRandom.uuid }
      let(:e) { SecureRandom.uuid }

      before do
        create_link_set(a, links_hash: { ordered_related_items: [b] })
        create_link_set(b, links_hash: { mainstream_browse_pages: [c] })
        create_link_set(c, links_hash: { parent: [d] })
        create_link_set(d, links_hash: { parent: [e] })
        create_link_set(e, links_hash: { parent: [content_id] })
      end

      it "has a dependency to all items" do
        expect(dependency_resolution).to match_array([a, b, c, d, e])
      end
    end
  end

  context "where there are recursive reverse links: child_taxons" do
    let(:a) { SecureRandom.uuid }
    let(:b) { SecureRandom.uuid }
    let(:c) { SecureRandom.uuid }
    let(:d) { SecureRandom.uuid }

    before do
      # parent_taxons reverses to child_taxons
      create_link_set(content_id, links_hash: { parent_taxons: [a] })
      create_link_set(a, links_hash: { parent_taxons: [b] })
      create_link_set(b, links_hash: { parent_taxons: [c] })
      create_link_set(c, links_hash: { parent_taxons: [d] })
    end

    it "has a dependency to all items" do
      expect(dependency_resolution).to match_array([a, b, c, d])
    end
  end

  context "when there is an edition that has an edition link to content_id" do
    let(:edition_content_id) { SecureRandom.uuid }
    let(:edition_locale) { :en }
    let(:link_type) { :organistion }
    before do
      create_edition(edition_content_id, "/edition-links",
        factory: edition_factory,
        locale: edition_locale,
        links_hash: { link_type => [content_id] },
      )
    end

    context "and the edition is a draft" do
      let(:edition_factory) { :draft_edition }
      context "and we're including drafts" do
        let(:with_drafts) { true }
        it "has a dependency of the edition" do
          expect(dependency_resolution).to match_array([edition_content_id])
        end
      end

      context "but we aren't including drafts" do
        let(:with_drafts) { false }
        it "does not have a dependency of the edition" do
          expect(dependency_resolution).to be_empty
        end
      end
    end

    context "and the edition is superseded" do
      let(:edition_factory) { :superseded_edition }

      it "does not have a dependency of the edition" do
        expect(dependency_resolution).to be_empty
      end
    end

    context "and the edition is in a different locale" do
      let(:edition_factory) { :live_edition }
      let(:edition_locale) { :fr }

      it "does not have a dependency of the edition" do
        expect(dependency_resolution).to be_empty
      end
    end

    context "and both the dependency resolution target and edition are in a non-en locale" do
      let(:edition_factory) { :live_edition }
      let(:edition_locale) { :fr }
      let(:locale) { :fr }

      it "has a dependency of the edition" do
        expect(dependency_resolution).to match_array([edition_content_id])
      end
    end

    context "and there is also a link of the same link_type in a link set" do
      let(:links_to_content_id) { SecureRandom.uuid }
      let(:edition_factory) { :live_edition }

      before do
        create_link_set(links_to_content_id,
          links_hash: { link_type => [content_id] },
        )
      end

      it "merges the links to return both" do
        expect(dependency_resolution).to match_array([edition_content_id, links_to_content_id])
      end
    end
  end

  context "when an edition links to an item that links to the content_id with a recursive link type" do
    let(:link_content_id) { SecureRandom.uuid }
    let(:edition_content_id) { SecureRandom.uuid }
    let(:link_type) { :parent_taxons }

    before do
      create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      create_edition(edition_content_id, "/edition-links",
        links_hash: { link_type => [link_content_id] },
      )
    end

    it "only has a dependency of the link as recusive edition links aren't supported" do
      expect(dependency_resolution).to match_array([link_content_id])
    end
  end
end
