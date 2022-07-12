RSpec.describe LinkSet do
  subject(:link_set) { create(:link_set) }

  describe "links_changed?" do
    let(:other_links) { [] }
    subject(:links_changed?) { link_set.links_changed?(other_links) }

    context "with no links" do
      it { is_expected.to be false }
    end

    context "with only saved links" do
      before { create(:link, link_set:) }

      it { is_expected.to be true }
    end

    context "with only other links" do
      let(:other_links) { [build(:link, link_set:)] }

      it { is_expected.to be true }
    end

    context "with the same other links" do
      let(:link) { create(:link, link_set:) }
      let(:other_links) { [build(:link, link_set:, target_content_id: link.target_content_id)] }

      it { is_expected.to be false }
    end

    context "with different other links" do
      let(:target_content_id) { SecureRandom.uuid }
      let(:link_type) { "link_type" }
      let(:position) { 0 }

      let(:link) do
        create(
          :link,
          link_set:,
          target_content_id:,
          link_type:,
          position:,
        )
      end
      let(:other_link) { nil }
      let(:other_links) { [other_link] }

      context "different target_content_id" do
        let(:other_link) do
          build(:link, target_content_id: SecureRandom.uuid, link_type:, position:)
        end

        it { is_expected.to be true }
      end

      context "different link_type" do
        let(:other_link) do
          build(:link, target_content_id:, link_type: "link_type2", position:)
        end

        it { is_expected.to be true }
      end

      context "different position" do
        let(:other_link) do
          build(:link, target_content_id:, link_type:, position: 1)
        end

        it { is_expected.to be true }
      end
    end
  end
end
