require "rails_helper"

RSpec.describe DependencyResolution::LinkReference do
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
