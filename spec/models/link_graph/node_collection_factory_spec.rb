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
      allow(link_reference).to receive(:root_links_by_link_type)
        .and_return(links, {})
      allow(link_reference).to receive(:child_links_by_link_type)
        .and_return({}, {})
    end

    context "no links" do
      let(:links) { {} }
      it { is_expected.to be_empty }
    end

    context "has links" do
      let(:link_hashes) do
        [
          { content_id: SecureRandom.uuid },
          { content_id: SecureRandom.uuid },
        ]
      end
      let(:links) { { parent: link_hashes } }
      let(:link_nodes) do
        link_hashes.map do |l|
          LinkGraph::Node.new(
            content_id: l[:content_id],
            locale: nil,
            edition_id: nil,
            link_type: :parent,
            parent: nil,
            link_graph: link_graph,
          )
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
