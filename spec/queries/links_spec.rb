RSpec.describe Queries::Links do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }

  describe ".from" do
    subject(:result) { described_class.from(content_id) }

    context "when there is not a link" do
      it { is_expected.to(be {}) }
    end

    context "when there is a link" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
      end

      it "returns a hash" do
        expect(result).to match(
          link_type => [a_hash_including(content_id: link_content_id)],
        )
      end
    end

    context "when there are multiple links of the same type" do
      let(:link_type) { "organisations" }

      context "and they have different positions" do
        let(:link_set) { create(:link_set, content_id:) }
        let!(:first_link) { create(:link, link_type:, link_set:, position: 1) }
        let!(:third_link) { create(:link, link_type:, link_set:, position: 3) }
        let!(:second_link) { create(:link, link_type:, link_set:, position: 2) }

        it "orders by position" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            first_link.target_content_id,
            second_link.target_content_id,
            third_link.target_content_id,
          ]
        end
      end

      context "and they have the same position" do
        let(:link_set) { create(:link_set, content_id:) }
        let!(:first_link) { create(:link, link_type:, link_set:, position: 0) }
        let!(:second_link) { create(:link, link_type:, link_set:, position: 0) }

        it "reverse orders by link ID" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            second_link.target_content_id,
            first_link.target_content_id,
          ]
        end
      end
    end

    describe "allowed_link_types option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      let(:allowed_link_types) { [link_type] }
      subject(:result) do
        described_class.from(content_id, allowed_link_types:)
      end
      before do
        create_link_set(content_id, links_hash: { link_type => [link_content_id] })
      end

      context "when a link is in allowed_link_types" do
        it { is_expected.not_to be_empty }
      end

      context "when a link is not in the allowed_link_types" do
        let(:allowed_link_types) { [:different] }
        it { is_expected.to be_empty }
      end

      context "when allowed_link_types is empty" do
        let(:allowed_link_types) { [] }
        it { is_expected.to eq({}) }
      end
    end
  end

  describe ".to" do
    subject(:result) { described_class.to(content_id) }

    context "when there is not a link" do
      it { is_expected.to(be {}) }
    end

    context "when there is a link" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      before do
        create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      end

      it "returns a hash" do
        expect(result).to match(
          link_type => [a_hash_including(content_id: link_content_id)],
        )
      end
    end

    context "when there are multiple links of the same type" do
      let(:link_type) { "organisations" }

      context "and they have different positions" do
        let!(:first_link) do
          create(
            :link,
            link_type:,
            target_content_id: content_id,
            position: 1,
          )
        end
        let!(:third_link) do
          create(
            :link,
            link_type:,
            target_content_id: content_id,
            position: 3,
          )
        end
        let!(:second_link) do
          create(
            :link,
            link_type:,
            target_content_id: content_id,
            position: 2,
          )
        end

        it "orders by position" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            first_link.link_set_content_id,
            second_link.link_set_content_id,
            third_link.link_set_content_id,
          ]
        end
      end

      context "and they have the same position" do
        let!(:first_link) do
          create(
            :link,
            link_type:,
            target_content_id: content_id,
            position: 0,
          )
        end
        let!(:second_link) do
          create(
            :link,
            link_type:,
            target_content_id: content_id,
            position: 0,
          )
        end

        it "reverse orders by link ID" do
          expect(result[:organisations].map { _1[:content_id] }).to eq [
            second_link.link_set_content_id,
            first_link.link_set_content_id,
          ]
        end
      end
    end

    describe "allowed_link_types option" do
      let(:link_content_id) { SecureRandom.uuid }
      let(:link_type) { :organisations }
      let(:allowed_link_types) { [link_type] }
      subject(:result) do
        described_class.to(content_id, allowed_link_types:)
      end
      before do
        create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      end

      context "when a link is in allowed_link_types" do
        it { is_expected.not_to be_empty }
      end

      context "when a link is not in the allowed_link_types" do
        let(:allowed_link_types) { [:different] }
        it { is_expected.to be_empty }
      end
    end
  end
end
