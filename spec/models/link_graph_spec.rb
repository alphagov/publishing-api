RSpec.describe LinkGraph do
  let(:content_id) { SecureRandom.uuid }
  let(:with_drafts) { false }
  let(:locale) { nil }
  let(:link_graph) do
    described_class.new(
      root_content_id: content_id,
      root_locale: locale,
      with_drafts: with_drafts,
      link_reference: double(:link_reference),
    )
  end

  describe "#links_content_ids" do
    subject { link_graph.links_content_ids }
    before { allow(link_graph).to receive(:links).and_return(links) }

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
    subject { link_graph.to_h }
    before { allow(link_graph).to receive(:links).and_return(links) }

    context "no links" do
      let(:links) { [] }

      it { is_expected.to be_empty }
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
          parent: [{ content_id: a, links: {} }],
          organisation: [
            { content_id: b, links: {} },
            { content_id: c, links: {} },
          ],
        }
      end

      it { is_expected.to match(expected) }
    end
  end
end
