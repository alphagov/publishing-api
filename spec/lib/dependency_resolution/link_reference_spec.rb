require "rails_helper"

RSpec.describe DependencyResolution::LinkReference do
  include DependencyResolutionHelper

  describe "#links_by_link_type" do
    let(:content_id) { SecureRandom.uuid }
    let(:with_drafts) { false }
    let(:link_types_path) { [] }
    let(:parent_content_ids) { [] }
    let(:locales) { %w(en) }

    subject do
      described_class.new.links_by_link_type(
        content_id,
        with_drafts,
        locales,
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
          create_link_set(content_id, links_hash: { parent: reverse_links })
          direct_links.each do |id|
            create_link_set(id, links_hash: { organisations: [content_id] })
          end
        end

        it { is_expected.to match(organisations: match_array(direct_links), children: reverse_links) }
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
          create_link_set(parent, links_hash: { parent: [content_id] })
        end
        it { is_expected.to match(parent: [parent]) }
      end

      context "direct non-recursive link" do
        let(:organisation) { SecureRandom.uuid }
        before do
          create_link_set(organisation, links_hash: { organisation: [content_id] })
        end
        it { is_expected.to be_empty }
      end

      context "reverse recursive link" do
        let(:link_types_path) { [:child_taxons] }
        let(:child) { SecureRandom.uuid }
        before do
          create_link_set(content_id, links_hash: { parent_taxons: [child] })
        end
        it { is_expected.to match(child_taxons: [child]) }
      end
    end
  end

  describe "#valid_link_node?" do
    let(:node) { double(:node, link_types_path: link_types_path, links: node_links) }
    let(:node_links) { [] }
    subject { described_class.new.valid_link_node?(node) }

    context "a single item in link_types_path" do
      let(:link_types_path) { [:anything] }
      it { is_expected.to be true }
    end

    context "child links are present on the node" do
      let(:link_types_path) { [:anything, :anything] }
      let(:node_links) { [SecureRandom.uuid, SecureRandom.uuid] }
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
