require "rails_helper"

RSpec.describe LinkExpansion::LinkReference do
  include DependencyResolutionHelper

  describe "#links_by_link_type" do
    let(:content_id) { SecureRandom.uuid }
    let(:link_types_path) { [] }
    let(:parent_content_ids) { [] }
    let(:with_drafts) { false }

    subject do
      described_class.new.links_by_link_type(
        content_id,
        with_drafts,
        link_types_path,
        parent_content_ids
      )
    end

    context "no links" do
      it { is_expected.to be_empty }
    end

    context "empty link_types_path" do
      context "with direct links" do
        let(:direct_links) { [SecureRandom.uuid, SecureRandom.uuid] }
        let(:reverse_links) { [SecureRandom.uuid, SecureRandom.uuid] }
        before do
          create_link_set(content_id, links_hash: { organisations: direct_links })
          reverse_links.each do |id|
            create_link_set(id, links_hash: { parent: [content_id] })
          end
        end

        it { is_expected.to match(organisations: direct_links, children: match_array(reverse_links)) }
      end
    end

    context "populated link_types_path" do
      let(:link_types_path) { [:parent] }

      context "no link" do
        it { is_expected.to be_empty }
      end

      context "direct recursive link" do
        let(:parent) { SecureRandom.uuid }
        before do
          create_link_set(content_id, links_hash: { parent: [parent] })
        end
        it { is_expected.to match(parent: [parent]) }
      end

      context "direct non-recursive link" do
        let(:organisation) { SecureRandom.uuid }
        before do
          create_link_set(content_id, links_hash: { organisation: [organisation] })
        end
        it { is_expected.to be_empty }
      end

      context "reverse recursive link" do
        let(:link_types_path) { [:child_taxons] }
        let(:child) { SecureRandom.uuid }
        before do
          create_link_set(child, links_hash: { parent_taxons: [content_id] })
        end
        it { is_expected.to match(child_taxons: [child]) }
      end
    end
  end

  describe "#valid_link_node?" do
    let(:node) { double(:node, link_types_path: link_types_path) }
    subject { described_class.new.valid_link_node?(node) }

    context "a single item in link_types_path" do
      let(:link_types_path) { [:anything] }
      it { is_expected.to be true }
    end

    context "a valid multi item link_types_path" do
      let(:link_types_path) { [:child_taxons, :child_taxons] }
      it { is_expected.to be true }
    end

    context "an invalid multi item link_types_path" do
      let(:link_types_path) { [:child_taxons, :parent] }
      it { is_expected.to be false }
    end
  end
end
