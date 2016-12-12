require "rails_helper"

RSpec.describe Queries::LinkedTo do
  def create_link_set(content_id, links_hash)
    FactoryGirl.create(:link_set, content_id: content_id, links_hash: links_hash)
  end

  describe "#call" do
    subject { described_class.new(content_id, expansion_rules).call }
    let(:content_id) { SecureRandom.uuid }
    let(:expansion_rules) { Queries::DependeeExpansionRules }
    let(:recursive_link_types) { [] }

    before do
      allow(expansion_rules).to receive(:recursive_link_types)
        .and_return(recursive_link_types)
    end
    context "when there are no links" do
      it { is_expected.to be_empty }
    end

    context "when our content item links to items but they don't link back" do
      before { create_link_set(content_id, organistion: [SecureRandom.uuid]) }

      it { is_expected.to be_empty }
    end

    context "when there are links to our content item" do
      let(:links_to_content_id) { SecureRandom.uuid }
      let(:linked_to) { [links_to_content_id] }
      before { create_link_set(links_to_content_id, organistion: [content_id]) }

      it { is_expected.to match_array(linked_to) }
    end

    context "when an item links to an item that links to us" do
      let(:a) { SecureRandom.uuid }
      let(:b) { SecureRandom.uuid }
      before do
        create_link_set(a, organisation: [content_id])
        create_link_set(b, organisation: [a])
      end

      it { is_expected.to match_array([a]) }

      context "and the link type is within the recursive link types" do
        let(:recursive_link_types) do
          [
            [:organisation]
          ]
        end

        it { is_expected.to match_array([a, b]) }
      end
    end

    context "when there is a cyclic link structure" do
      let(:a) { SecureRandom.uuid }
      let(:b) { SecureRandom.uuid }
      let(:recursive_link_types) do
        [
          [:parent]
        ]
      end

      # a links to b, b links to a
      before do
        create_link_set(a, parent: [content_id, b])
        create_link_set(b, parent: [a])
      end

      it { is_expected.to match_array([a, b]) }
    end

    context "when a recursive path is ordered_related_items, mainstream_browse_pages, parent" do
      let(:recursive_link_types) do
        [
          [:ordered_related_items, :mainstream_browse_pages, :parent]
        ]
      end
      let(:a) { SecureRandom.uuid }
      let(:b) { SecureRandom.uuid }
      let(:c) { SecureRandom.uuid }

      context "and the links match this path" do
        before do
          create_link_set(a, ordered_related_items: [b])
          create_link_set(b, mainstream_browse_pages: [c])
          create_link_set(c, parent: [content_id])
        end

        it { is_expected.to match_array([a, b, c]) }
      end

      context "but the links don't match this path" do
        before do
          create_link_set(a, mainstream_browse_pages: [b])
          create_link_set(b, ordered_related_items: [c])
          create_link_set(c, parent: [content_id])
        end

        it { is_expected.to match_array([c]) }
      end

      context "and there are additional parent links" do
        let(:d) { SecureRandom.uuid }
        let(:e) { SecureRandom.uuid }

        before do
          create_link_set(a, ordered_related_items: [b])
          create_link_set(b, mainstream_browse_pages: [c])
          create_link_set(c, parent: [d])
          create_link_set(d, parent: [e])
          create_link_set(e, parent: [content_id])
        end

        it { is_expected.to match_array([a, b, c, d, e]) }
      end
    end
  end
end
