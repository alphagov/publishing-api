require "rails_helper"

RSpec.describe LinkGraph::NodeCollectionFactory do
  let(:link_reference) { double(:link_reference, valid_link_node?: valid_link_node) }
  let(:link_graph) do
    double(:link_graph,
      link_reference: link_reference,
      root_content_id: SecureRandom.uuid,
      root_locale: :en,
      with_drafts: false,
    )
  end
  let(:valid_link_node) { true }

  describe "#collection" do
    subject { described_class.new(link_graph, nil).collection }
    before do
      allow(link_reference).to receive(:links_by_link_type)
        .and_return(links, {})
    end

    context "no links" do
      let(:links) { {} }
      it { is_expected.to be_empty }
    end

    context "has links" do
      let(:content_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let(:links) { { parent: content_ids } }
      let(:link_nodes) do
        content_ids.map do |content_id|
          LinkGraph::Node.new(content_id, :parent, nil, link_graph)
        end
      end

      it { is_expected.to match_array(link_nodes) }

      context "but the first is invalid" do
        before do
          allow(link_reference).to receive(:valid_link_node?)
            .and_return(false, true)
        end

        it { is_expected.to match_array([link_nodes.last]) }
      end
    end
  end
end
