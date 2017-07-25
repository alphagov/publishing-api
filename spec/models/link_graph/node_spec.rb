require "rails_helper"

RSpec.describe LinkGraph::Node do
  let(:content_id) { SecureRandom.uuid }
  let(:link_type) { :organisation }
  let(:parent) { nil }
  let(:link_graph) { double(:link_graph) }
  let(:has_own_links) { nil }
  let(:is_linked_to) { nil }
  let(:node) do
    described_class.new(
      content_id: content_id,
      locale: nil,
      edition_id: nil,
      link_type: link_type,
      parent: parent,
      link_graph: link_graph,
      has_own_links: has_own_links,
      is_linked_to: is_linked_to,
    )
  end

  describe "#link_types_path" do
    subject { node.link_types_path }
    context "has no parent" do
      let(:parent) { nil }
      it { is_expected.to match_array([link_type]) }
    end

    context "has a parent" do
      let(:parent) do
        described_class.new(
          content_id: SecureRandom.uuid,
          locale: nil,
          edition_id: nil,
          link_type: :parent,
          parent: nil,
          link_graph: link_graph,
        )
      end
      it { is_expected.to match_array([:parent, link_type]) }
    end
  end

  describe "#links_content_ids" do
    subject { node.links_content_ids }
    before { allow(node).to receive(:links).and_return(links) }

    context "no links" do
      let(:links) { [] }

      it { is_expected.to be_empty }
    end

    context "with links" do
      let(:a) { SecureRandom.uuid }
      let(:b) { SecureRandom.uuid }
      let(:c) { SecureRandom.uuid }
      let(:d) { SecureRandom.uuid }

      let(:links) do
        [
          double(:link, content_id: a, links_content_ids: [b, c]),
          double(:link, content_id: d, links_content_ids: [b]),
        ]
      end

      it { is_expected.to match_array([a, b, c, d]) }
    end
  end

  describe "#to_h" do
    subject { node.to_h }
    before { allow(node).to receive(:links).and_return(links) }

    context "no links" do
      let(:links) { [] }

      it { is_expected.to match(content_id: content_id, links: {}) }
    end

    context "with links" do
      let(:a) { SecureRandom.uuid }
      let(:b) { SecureRandom.uuid }
      let(:c) { SecureRandom.uuid }

      let(:links) do
        [
          double(:link, link_type: :parent, to_h: { content_id: a, links: {} }),
          double(:link, link_type: :organisation, to_h: { content_id: b, links: {} }),
          double(:link, link_type: :organisation, to_h: { content_id: c, links: {} }),
        ]
      end

      let(:expected) do
        {
          content_id: content_id,
          links: {
            parent: [{ content_id: a, links: {} }],
            organisation: [
              { content_id: b, links: {} },
              { content_id: c, links: {} },
            ],
          }
        }
      end

      it { is_expected.to match(expected) }
    end
  end

  describe "#might_have_links?" do
    subject { node.might_have_links? }

    context "when initialised with has_own_links and is_linked_to as false" do
      let(:has_own_links) { false }
      let(:is_linked_to) { false }

      it { is_expected.to be false }
    end

    context "when it doesn't know whether it has has own links" do
      let(:has_own_links) { nil }
      let(:is_linked_to) { false }

      it { is_expected.to be true }
    end

    context "when it knows whether it has own links" do
      let(:has_own_links) { true }
      let(:is_linked_to) { false }

      it { is_expected.to be true }
    end
  end
end
