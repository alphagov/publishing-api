require "rails_helper"

RSpec.describe LinkExpansion do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  describe "#links_with_content" do
    subject do
      described_class.by_content_id(content_id).links_with_content
    end

    context "no links" do
      it { is_expected.to be_empty }
      it { is_expected.to be_a(Hash) }
    end

    context "with a link" do
      let(:link) do
        create(
          :live_edition,
          title: "Expanded Link",
          base_path: "/expanded-link",
        )
      end

      let(:expected) do
        {
          related: [
            a_hash_including(title: link.title, base_path: link.base_path),
          ],
        }
      end

      before { create_link(content_id, link.document.content_id, "related") }

      it { is_expected.to match(expected) }
    end

    context "with a withdrawn link" do
      let(:link) { create(:withdrawn_unpublished_edition) }

      before { create_link(content_id, link.document.content_id, link_type) }

      context "and a parent link_type" do
        let(:link_type) { :parent }

        it { is_expected.to match(parent: [a_hash_including(withdrawn: true)]) }
      end

      context "and a related link_type" do
        let(:link_type) { :related }

        it { is_expected.to be_empty }
      end

      context "and a related_statistical_data_sets link_type" do
        let(:link_type) { :related_statistical_data_sets }

        it { is_expected.to match(related_statistical_data_sets: [a_hash_including(withdrawn: true)]) }
      end
    end

    context "with recursive links" do
      let(:child_content_id) { SecureRandom.uuid }
      let(:grand_child_content_id) { SecureRandom.uuid }
      let!(:child) { create_edition(child_content_id, "/child") }
      let!(:grand_child) { create_edition(grand_child_content_id, "/grand-child") }

      before do
        create_link(content_id, child_content_id, "parent")
        create_link(child_content_id, grand_child_content_id, "parent")
      end

      let(:expected) do
        {
          parent: [a_hash_including(
            base_path: child.base_path,
            links: {
              parent: [a_hash_including(
                base_path: grand_child.base_path,
                links: {},
              )],
            },
          )],
        }
      end

      it { is_expected.to match(expected) }
    end
  end
end
