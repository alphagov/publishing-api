require "rails_helper"

RSpec.describe "Edition Links" do
  include DependencyResolutionHelper

  let(:locale) { "en" }
  let(:with_drafts) { false }
  let(:source_content_id) { SecureRandom.uuid }

  subject(:expanded_links) do
    LinkExpansion.by_content_id(
      source_content_id,
      locale: locale,
      with_drafts: with_drafts,
    ).links_with_content
  end

  context "when there are no edition links" do
    it "performs no expansion" do
      expect(expanded_links).to be_empty
    end
  end

  shared_examples "has link" do |base_path: "/target", link_type: :test|
    it "has links of type #{link_type}" do
      expect(expanded_links).to include(link_type)
    end

    it "has a link to target of type #{link_type}" do
      expect(expanded_links[link_type]).to match_array([
        a_hash_including(base_path: base_path)
      ])
    end
  end

  shared_examples "doesn't have link" do
    it "has no links of type test" do
      expect(expanded_links).to_not include(:test)
    end
  end

  context "with a single direct edition link" do
    let(:source_factory) { :live_edition }
    let(:target_factory) { :live_edition }
    let(:source_locale) { :en }
    let(:target_locale) { :en }
    let(:target_content_id) { SecureRandom.uuid }

    before do
      create_edition(source_content_id, "/source",
        factory: source_factory,
        locale: source_locale,
        links_hash: { test: [target_content_id] })

      create_edition(target_content_id, "/target",
        locale: target_locale,
        factory: target_factory)
    end

    context "when target is published" do
      include_examples "has link"
    end

    context "when target is published and source is draft" do
      let(:source_factory) { :draft_edition }
      include_examples "doesn't have link"
    end

    context "when target is published and source is draft but we include drafts" do
      let(:source_factory) { :draft_edition }
      let(:with_drafts) { true }
      include_examples "has link"
    end

    context "when target is draft" do
      let(:target_factory) { :draft_edition }
      include_examples "doesn't have link"
    end

    context "when target is draft and source is draft" do
      let(:target_factory) { :draft_edition }
      let(:source_factory) { :draft_edition }
      include_examples "doesn't have link"
    end

    context "when target is draft and source is draft but we include drafts" do
      let(:target_factory) { :draft_edition }
      let(:source_factory) { :draft_edition }
      let(:with_drafts) { true }
      include_examples "has link"
    end

    context "with a draft and published target" do
      before do
        create_edition(target_content_id, "/target.draft",
          factory: :draft_edition,
          version: 2)
      end

      include_examples "has link"

      context "but we include drafts" do
        let(:with_drafts) { true }
        include_examples "has link", base_path: "/target.draft"
      end
    end

    context "with a superseded target" do
      let(:target_factory) { :superseded_edition }
      include_examples "doesn't have link"
    end

    context "with an english source and french target" do
      let(:target_locale) { :fr }
      include_examples "doesn't have link"
    end

    context "with an french source and french target" do
      let(:source_locale) { :fr }
      let(:target_locale) { :fr }
      let(:locale) { :fr }
      include_examples "has link"
    end
  end

  context "with a single edition link that is of a reverse link type" do
    let(:parent_content_id) { SecureRandom.uuid }
    let(:child_content_id) { SecureRandom.uuid }

    before do
      create_edition(child_content_id, "/child",
        links_hash: { parent: [parent_content_id] })

      create_edition(parent_content_id, "/parent")
    end

    context "when the parent is the source" do
      let(:source_content_id) { parent_content_id }
      include_examples "has link", link_type: :children, base_path: "/child"

      it "should include the parent in the link" do
        expect(expanded_links[:children][0][:links]).to include(:parent)
        expect(expanded_links[:children][0][:links][:parent]).to match_array([
          a_hash_including(base_path: "/parent")
        ])
      end
    end

    context "when the child is the source" do
      let(:source_content_id) { child_content_id }
      include_examples "has link", link_type: :parent, base_path: "/parent"
    end
  end

  context "with an edition link that is of a recursive link type" do
    let(:child_content_id) { SecureRandom.uuid }
    let(:parent_content_id) { SecureRandom.uuid }
    let(:grandparent_content_id) { SecureRandom.uuid }
    let(:source_content_id) { child_content_id }

    before do
      create_edition(child_content_id, "/child",
        links_hash: { parent: [parent_content_id] })

      create_edition(parent_content_id, "/parent")
      create_edition(grandparent_content_id, "/grandparent")
      create_link(parent_content_id, grandparent_content_id, :parent)
    end

    include_examples "has link", link_type: :parent, base_path: "/parent"

    it "should not find links within an edition link" do
      expect(expanded_links[:parent][0][:links]).to be_empty
    end
  end

  context "with both edition links and link set links " do
    let(:edition_target_content_id) { SecureRandom.uuid }
    let(:linkset_target_content_id) { SecureRandom.uuid }
    let(:edition_link_type) { :test }
    let(:linkset_link_type) { :test }

    before do
      create_edition(source_content_id, "/source",
        links_hash: { edition_link_type => [edition_target_content_id] })

      create_edition(edition_target_content_id, "/target")
      create_edition(linkset_target_content_id, "/other-target")

      create_link(source_content_id, linkset_target_content_id, linkset_link_type)
    end

    context "and they are of the same link type" do
      it "has only the edition link as edition links take precedence" do
        expect(expanded_links[:test]).to match_array([
          a_hash_including(base_path: "/target"),
        ])
      end
    end

    context "and they are different link types" do
      let(:linkset_link_type) { :test2 }

      it "has both the edition link and linkset link" do
        expect(expanded_links[:test]).to match_array([
          a_hash_including(base_path: "/target"),
        ])

        expect(expanded_links[:test2]).to match_array([
          a_hash_including(base_path: "/other-target"),
        ])
      end
    end
  end
end
